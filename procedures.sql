
----------- BỘ PHẬN CHĂM SÓC KHÁCH HÀNG
CREATE OR ALTER PROCEDURE sp_TimPhanHang
	@MaKH int, @MaPH int OUTPUT
AS
BEGIN
	-- Khai báo mốc thời gian bắt đầu tính tiền mua sắm
	DECLARE @TGBatDau DATE,
			@TongTien INT

	-- Xác định khoảng thời gian tính tiền mua sắm
	SELECT @TGBatDau = DATEADD(year, DATEDIFF(year, NgayDangKy, GETDATE()), NgayDangKy)
	FROM KHACHHANG WITH (NOLOCK)
	WHERE MaKH = @MaKH

	IF @TGBatDau > GETDATE()
	BEGIN
		SET @TGBatDau = DATEADD(year, -1, @TGBatDau)
	END

	-- Tính tổng số tiền khách hàng đã mua trong khoảng thời gian xác định
	SELECT @TongTien = ISNULL(SUM(TongPhaiTra), 0)
	FROM DONHANG
	WHERE NgayDat >= @TGBatDau AND MaKH = @MaKH

	--  Xác định phân hạng
	SELECT @MaPH = MaPH
	FROM PHANHANG WITH (NOLOCK)
	WHERE @TongTien >= TongMin 
	AND (@TongTien < TongMax OR TongMax is NULL)
END
GO

CREATE OR ALTER PROCEDURE sp_PhanHangKhachHang
	@MaNV int
AS
BEGIN
	DECLARE @MaKH int,
			@MaPH int

	DECLARE cur CURSOR LOCAL FOR
	SELECT MaKH
	FROM KHACHHANG

	OPEN cur
	FETCH NEXT FROM cur INTO @MaKH

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRANSACTION
			SET TRANSACTION ISOLATION LEVEL SERIALIZABLE 
			-- Tìm phân hạng
			EXEC sp_TimPhanHang @MaKH, @MaPH OUTPUT

			-- Cập nhật phân hạng
			UPDATE KHACHHANG
			SET MaPH = @MaPH, MaNV = @MaNV
			WHERE MaKH = @MaKH
		COMMIT TRANSACTION

		FETCH NEXT FROM cur INTO @MaKH
	END

	CLOSE cur
	DEALLOCATE cur

	print N'Hoàn tất phân hạng khách hàng'
END
GO

CREATE OR ALTER PROCEDURE sp_TangPhieuMuaHang
	@MaNV int
AS
BEGIN
	DECLARE @MaKH int,
			@MaPH int,
			@MaLP int,
			@tmp int

	SET @tmp = 11

	-- Tìm những khách hàng có sinh nhật trong tháng
	DECLARE cur CURSOR LOCAL FOR
	SELECT MaKH 
	FROM KHACHHANG
	WHERE Month(NgaySinh) = Month(GETDATE())

	OPEN cur
	FETCH NEXT FROM cur INTO @MaKH

	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRANSACTION
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
			-- Xác định phân hạng khách hàng
			SELECT @MaPH = MaPH
			FROM KHACHHANG WITH (ROWLOCK)
			WHERE MaKH = @MaKH

			-- Xác định loại phiếu mua hàng tương ứng
			SELECT @MaLP = MaLP
			FROM LOAIPHIEUMUAHANG WITH (NOLOCK)
			WHERE MaPH = @MaPH

			-- Tặng phiếu mua hàng
			INSERT INTO PHIEUMUAHANG (MaKH, NgayTang, MaLP, MaNV, HanSuDung, TrangThai)
			VALUES (@MaKH, GETDATE(), @MaLP, @MaNV, EOMONTH(GETDATE()), N'Chưa sử dụng')

		COMMIT TRANSACTION
		FETCH NEXT FROM cur INTO @MaKH
	END

	CLOSE cur
	DEALLOCATE cur
	
	print N'Tặng phiếu mua hàng hoàn tất'
END

----------- BỘ PHẬN QUẢN LÝ NGÀNH HÀNG
----------------------------- sp_ThemSanPham -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_ThemSanPham
    @MaDM INT,
    @MaNSX INT,
    @TenSP NVARCHAR(255),
    @MoTa TEXT,
    @GiaNiemYet INT,
    @SLToiDa INT,
    @SLTonKho INT,
    @DonVi NVARCHAR(255)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        DECLARE @MaSP INT;
        SELECT @MaSP = ISNULL(MAX(MaSP), 0) + 1 FROM SANPHAM;

        IF NOT EXISTS (
            SELECT 1 
            FROM SANPHAM WITH (ROWLOCK, UPDLOCK) 
            WHERE TenSP = @TenSP AND MaDM = @MaDM AND MaNSX = @MaNSX
        )
        BEGIN
            INSERT INTO SANPHAM (
                MaSP, TenSP, MoTa, GiaNiemYet, SLToiDa, SLTonKho, DonVi, NgayThem, NgayCapNhat, MaDM, MaNSX
            )
            VALUES (
                @MaSP, @TenSP, @MoTa, @GiaNiemYet, @SLToiDa, @SLTonKho, @DonVi, GETDATE(), GETDATE(), @MaDM, @MaNSX
            );

            PRINT N'Sản phẩm mới đã được thêm vào thành công.';
        END
        ELSE
        BEGIN
            PRINT N'Sản phẩm đã tồn tại trong hệ thống.';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT N'Lỗi khi thêm sản phẩm: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

----------------------------- sp_ThemKhuyenMai -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_ThemKhuyenMai
    @NgayBatDau DATETIME,
    @NgayKetThuc DATETIME,
    @TiLe FLOAT,
    @SLToiDa INT,
    @LoaiKM NVARCHAR(15),
    @MaSP1 INT = NULL,
    @MaSP2 INT = NULL,
    @MaPH INT = NULL,
    @MaNV INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

        DECLARE @MaKhuyenMai INT;
        SELECT @MaKhuyenMai = ISNULL(MAX(MaKhuyenMai), 0) + 1 
        FROM KHUYENMAI WITH (ROWLOCK);

        IF (@LoaiKM = 'Combo-sale' OR @LoaiKM = 'Flash-sale') AND @MaSP1 IS NOT NULL
        BEGIN
            DECLARE @SLTonKho INT;

            SELECT @SLTonKho = SLTonKho
            FROM SANPHAM WITH (ROWLOCK)
            WHERE MaSP = @MaSP1;

            IF @SLToiDa > @SLTonKho
            BEGIN
                PRINT N'Số lượng tối đa của khuyến mãi vượt quá số lượng tồn kho.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END

        INSERT INTO KHUYENMAI (
            MaKhuyenMai, NgayBatDau, NgayKetThuc, NgayTaoMaKM, TiLe, SLToiDa, TinhTrang, SLDaBan, LoaiKM, MaNV
        )
        VALUES (
            @MaKhuyenMai, @NgayBatDau, @NgayKetThuc, GETDATE(), @TiLe, @SLToiDa, N'Đang diễn ra', 0, @LoaiKM, @MaNV
        );

        IF @LoaiKM = 'Combo-sale'
        BEGIN
            INSERT INTO COMBOSALE (MaKhuyenMai, MaSP1, MaSP2)
            VALUES (@MaKhuyenMai, @MaSP1, @MaSP2);
        END
        ELSE IF @LoaiKM = 'Member-sale'
        BEGIN
            INSERT INTO MEMBERSALE (MaKhuyenMai, MaPH)
            VALUES (@MaKhuyenMai, @MaPH);
        END
        ELSE IF @LoaiKM = 'Flash-sale'
        BEGIN
            INSERT INTO FLASHSALE (MaKhuyenMai, MaSP)
            VALUES (@MaKhuyenMai, @MaSP1);
        END

        PRINT N'Khuyến mãi mới đã được thêm vào thành công.';

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT N'Lỗi khi thêm khuyến mãi: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

----------------------------- sp_TaoFlashSale -------------------------------------
CREATE OR ALTER PROCEDURE sp_TaoFlashSale
    @MaKM INT,
    @MaSP INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO FLASHSALE (MaKhuyenMai, MaSP)
        VALUES (@MaKM, @MaSP);

        PRINT N'Flash Sale đã được tạo thành công.';
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END
GO

----------------------------- sp_TaoComboSale -------------------------------------
CREATE OR ALTER PROCEDURE sp_TaoComboSale
    @MaKM INT,
    @MaSP1 INT,
    @MaSP2 INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO COMBOSALE (MaKhuyenMai, MaSP1, MaSP2)
        VALUES (@MaKM, @MaSP1, @MaSP2);

        PRINT N'Combo Sale đã được tạo thành công.';
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END
GO

----------------------------- sp_TaoMemberSale -------------------------------------
CREATE OR ALTER PROCEDURE sp_TaoMemberSale
    @MaKM INT,
    @MaPH INT
AS
BEGIN
    BEGIN TRY
        INSERT INTO MEMBERSALE (MaKhuyenMai, MaPH)
        VALUES (@MaKM, @MaPH);

        PRINT N'Member Sale đã được tạo thành công.';
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END
GO

----------- BỘ PHẬN XỬ LÝ ĐƠN HÀNG
----------- BỘ PHẬN KINH DOANH

----------- BỘ PHẬN QUẢN LÝ KHO HÀNG
----------------------------- sp_TinhSoLuongDatHang -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_TinhSoLuongDatHang
@MaSP INT, @SLDat INT OUT
AS
BEGIN
	DECLARE @TONG INT, @SLTon INT, @SLToiDa INT

	SELECT @SLToiDa=SLToiDa, @SLTon=SLTonKho
	FROM SANPHAM WITH ROWLOCK
	WHERE MaSP=@MaSP

	SELECT @TONG = SUM(SoLuong)
	FROM DONDATNSX WITH (REPEATABLEREAD)
	WHERE TinhTrang=N'Chưa giao' AND MaSP=@MaSP

	SET @SLDat = @SLToiDa - @SLTon - @TONG

END
GO

----------------------------- sp_TaoDonDatHang -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_TaoDonDatHang
@MaSP INT, @MaNSX INT, @SL INT, @MaNV INT
AS
BEGIN

	DECLARE @MATT INT
	SELECT @MATT = ISNULL(MAX(MaDDH)+1,1) FROM DONDATNSX WITH (XLOCK)

	INSERT INTO DONDATNSX (MaDDH,MaNSX,SoLuong,MaSP,NgayDat,TinhTrang,MaNV)
	VALUES (@MATT,@MaNSX,@SL,@MaSP,GETDATE(),N'Chưa giao',@MaNV)

END
GO

----------------------------- sp_DatSanPham -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_DatSanPham
    @MaNV INT
AS
BEGIN

    DECLARE SP_CUR CURSOR LOCAL FOR 
    SELECT MaSP, SLToiDa, MaNSX
    FROM SANPHAM WITH ROWLOCK
    WHERE SLTonKho < (0.7 * SLToiDa)

    DECLARE @MaSP INT, @SLDat INT, @SLToiDa INT, @MaNSX INT

    OPEN SP_CUR
    FETCH NEXT FROM SP_CUR INTO @MaSP, @SLToiDa, @MaNSX

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
           
            BEGIN TRANSACTION
            SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

            EXEC sp_TinhSoLuongDatHang @MaSP, @SLDat OUTPUT

            IF @SLDat >= 0.1 * @SLToiDa
            BEGIN
                EXEC sp_TaoDonDatHang @MaSP, @MaNSX, @SLDat, @MaNV
               
            END
            
            COMMIT TRANSACTION
        END TRY
        BEGIN CATCH
            ROLLBACK TRANSACTION
            PRINT N'Lỗi khi xử lý sản phẩm ' + CAST(@MaSP AS NVARCHAR) + N': ' + ERROR_MESSAGE()
        END CATCH
        
        FETCH NEXT FROM SP_CUR INTO @MaSP, @SLToiDa, @MaNSX
    END

    CLOSE SP_CUR
    DEALLOCATE SP_CUR

    PRINT N'Hoàn thành việc xử lý các sản phẩm.'
END
GO

----------------------------- sp_CapNhatSoLuongTonSauNhap -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_CapNhatSoLuongTonSauNhap
@MaSP INT, @SoLuongGiao INT
AS
BEGIN
	UPDATE SANPHAM WITH (XLOCK,ROWLOCK)
	SET SLTonKho=SLTonKho+@SoLuongGiao
	WHERE MaSP=@MaSP 
END
GO

----------------------------- sp_TaoCTDonNhanHang -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_TaoCTDonNhanHang
    @MaDNH INT, 
    @SoLuongGiao INT, 
    @DonGia INT, 
    @MaDDH INT
AS
BEGIN
    DECLARE @SLDat INT, @ThanhTien INT, @MaSP INT

    BEGIN TRANSACTION
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
  
    SELECT @SLDat = SoLuong, @MaSP = MaSP
    FROM DONDATNSX WITH (UPDLOCK, ROWLOCK)
    WHERE MaDDH = @MaDDH AND TinhTrang=N'Chưa giao'


    IF @SLDat IS NOT NULL AND @SoLuongGiao <= @SLDat 
    BEGIN

        UPDATE DONDATNSX
        SET TinhTrang = N'Đã giao'
        WHERE MaDDH = @MaDDH

        SET @ThanhTien = @SoLuongGiao * @DonGia

        EXEC sp_CapNhatSoLuongTonSauNhap @MaSP, @SoLuongGiao

        DECLARE @STT INT
        SELECT @STT = ISNULL(MAX(STT) + 1,1)
        FROM CTDONNHANHANG 
        WHERE MaDNH = @MaDNH

        INSERT INTO CTDONNHANHANG (STT, MaDNH, SoLuong, DonGia, ThanhTien, MaDDH)
        VALUES (@STT, @MaDNH, @SoLuongGiao, @DonGia, @ThanhTien, @MaDDH)

    END
    ELSE
    BEGIN
        PRINT N'Số lượng giao không hợp lệ hoặc vượt quá số lượng đặt hàng. Chi tiết đơn hàng không được xử lý.'
    END

    COMMIT TRANSACTION

END

----------------------------- sp_TaoDonNhanHang -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_TaoDonNhanHang
    @MaNSX INT,
    @MaNV INT,
    @CTDH NVARCHAR(MAX), -- JSON chứa danh sách chi tiết đơn nhận hàng
    @MaDNH INT OUTPUT     -- Giá trị trả về là mã đơn nhận hàng vừa tạo
AS
BEGIN
    BEGIN TRANSACTION

    BEGIN TRY
        -- Tạo một đơn nhận hàng mới
        INSERT INTO DONNHANHANG (MaNV, NgayNhan, TongTien, MaNSX)
        VALUES (@MaNV, GETDATE(), 0, @MaNSX);

        SET @MaDNH = SCOPE_IDENTITY();

        
        DECLARE @SoLuongGiao INT, @DonGia INT, @MaDDH INT;

        -- Duyệt từng phần tử trong JSON
        DECLARE cur_CTDH CURSOR FOR
        SELECT 
            JSON_VALUE(value, '$.SoLuongGiao') AS SoLuongGiao,
            JSON_VALUE(value, '$.DonGia') AS DonGia,
            JSON_VALUE(value, '$.MaDDH') AS MaDDH
        FROM OPENJSON(@CTDH);

        OPEN cur_CTDH;
        FETCH NEXT FROM cur_CTDH INTO @SoLuongGiao, @DonGia, @MaDDH;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Gọi thủ tục để thêm từng chi tiết đơn nhận hàng
            EXEC sp_TaoCTDonNhanHang @MaDNH, @SoLuongGiao, @DonGia, @MaDDH;

            FETCH NEXT FROM cur_CTDH INTO @SoLuongGiao, @DonGia, @MaDDH;
        END

        CLOSE cur_CTDH;
        DEALLOCATE cur_CTDH;

        -- Tính tổng tiền cho đơn nhận hàng vừa tạo
        UPDATE DONNHANHANG
        SET TongTien = (
            SELECT SUM(ThanhTien)
            FROM CTDONNHANHANG WITH (HOLDLOCK)
            WHERE MaDNH = @MaDNH
        )
        WHERE MaDNH = @MaDNH;

        COMMIT TRANSACTION;
        PRINT N'Hoàn thành việc tạo đơn nhập hàng.'
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT N'Lỗi: Không tạo đơn nhập hàng mới được.';
        THROW;
    END CATCH
END
GO



----------- PROCEDURE PHÁT SINH
----------------------------- sp_TaoChiTietDonHang   -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_TaoChiTietDonHang 
@MaDH INT, @MaSP INT, @SoLuong INT
AS
BEGIN
    BEGIN TRANSACTION
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE 
    DECLARE @SLTon INT, @Gia INT, @STT INT, @ThanhTien INT

    SELECT @SLTon=SLTonKho, @Gia=GiaNiemYet
    FROM SANPHAM WITH (REPEATABLEREAD)
    WHERE MaSP=@MaSP

    IF @SoLuong <= @SLTon
    BEGIN
        SELECT @STT = ISNULL(MAX(STT) + 1,1)
        FROM CTDONHANG
        WHERE MaDH=@MaDH

        SET @ThanhTien = @Gia * @SoLuong

        INSERT INTO CTDONHANG (MaDH, STT, MaSP, SoLuong, ThanhTien) 
        VALUES (@MaDH, @STT, @MaSP, @SoLuong, @ThanhTien)
    END
    COMMIT TRANSACTION

END
GO
----------------------------- sp_CapNhatSoLuongTonSauBan  -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_CapNhatSoLuongTonSauBan
@MaSP INT, @SoLuongBan INT
AS
BEGIN
	UPDATE SANPHAM WITH (XLOCK,ROWLOCK)
	SET SLTonKho=SLTonKho - @SoLuongBan
	WHERE MaSP=@MaSP 
END
GO

----------------------------- sp_CapNhatSanPham   -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_CapNhatSanPham 
@MaSP INT, @MaDM INT, @MaNSX INT, @TenSP NVARCHAR(255), @MoTa TEXT, @GiaNiemYet INT, @SLToiDa INT, @SLTonKho INT, @DonVi NVARCHAR(255)
AS
BEGIN
	UPDATE SANPHAM WITH (XLOCK, ROWLOCK)
	SET MaDM=@MaDM, MASP=@MaNSX, TenSP=@TenSP, MoTa=@MoTa, GiaNiemYet=@GiaNiemYet, SLToiDa=@SLToiDa, SLTonKho=@SLTonKho, DonVi=@DonVi
	WHERE MaSP=@MaSP 
END
GO

------------------------ LÁT NHỚ XÓA NHÉ --------------------------
------------------------ 1 PHAN sp_TaoDonHang --------------------------
CREATE OR ALTER PROCEDURE usp_TaoDonHang
	@NgayGiao DATETIME,
	@TinhTrang NVARCHAR(15),
	@MaNV INT,
	@MaKH INT,
	@CTDH NVARCHAR(MAX)
AS
BEGIN TRANSACTION
	DECLARE @MaDH INT

	-- Khởi tạo đơn hàng
	INSERT INTO DONHANG(NgayDat, NgayGiao, TinhTrang, MaNV, MaKH)
	VALUES (GETDATE(), @NgayGiao, @TinhTrang, @MaNV, @MaKH)

	SET @MaDH = SCOPE_IDENTITY();

	-- Lưu các chi tiết đơn hàng
	INSERT INTO CTDONHANG (MaDH, STT, MaSP, SoLuong)
	SELECT 
        @MaDH AS MaDH,
        JSON_VALUE(value, '$.STT') AS STT,
        JSON_VALUE(value, '$.MaSP') AS MaSP,
        JSON_VALUE(value, '$.SoLuong') AS SoLuong
    FROM OPENJSON(@CTDH);
COMMIT TRANSACTION

EXEC usp_TaoDonHang 
	NULL,
	N'Đang xử lý',
	1,
	1,
	N'[
		{
			"STT": 1,
			"MaSP": 1,
			"SoLuong": 2
		},
		{
			"STT": 2,
			"MaSP": 5,
			"SoLuong": 3
		}
	]'




