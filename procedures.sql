
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
----------------sp_ApDungKhuyenMai---------------

CREATE OR ALTER PROCEDURE sp_ApDungKhuyenMai
    @MaDH INT,        -- Mã đơn hàng
    @STT INT,         -- Số thứ tự
    @MaSP INT,        -- Mã sản phẩm
    @SoLuong INT      -- Số lượng
AS
BEGIN
    BEGIN TRANSACTION;

    -- Đặt mức độ cô lập giao dịch là SERIALIZABLE
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    -- 1. Xác định mã khuyến mãi có thể áp dụng cho sản phẩm
    DECLARE @MaKhuyenMai INT, @TiLe FLOAT, @SLToiDa INT, @SLDaBan INT;
    SELECT TOP 1 @MaKhuyenMai = MaKhuyenMai, 
                 @TiLe = TiLe, 
                 @SLToiDa = SLToiDa, 
                 @SLDaBan = SLDaBan
    FROM KHUYENMAI WITH (ROWLOCK)
    WHERE TinhTrang = N'Đang diễn ra'
      AND NgayBatDau <= GETDATE()
      AND NgayKetThuc >= GETDATE();

    IF @MaKhuyenMai IS NULL
    BEGIN
        PRINT 'Không có mã khuyến mãi hợp lệ';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2. Kiểm tra nếu tồn tại mã khuyến mãi
    IF @SLDaBan >= @SLToiDa
    BEGIN
        PRINT 'Mã khuyến mãi đã hết số lượng áp dụng';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 2.1. Xác định số lượng sản phẩm được giảm giá
    DECLARE @SoLuongGiam INT, @ThanhTien INT, @TienPhaiTra INT;
    SET @SoLuongGiam = CASE
        WHEN @SLDaBan + @SoLuong <= @SLToiDa THEN @SoLuong
        ELSE @SLToiDa - @SLDaBan
    END;

    -- 2.2. Cập nhật mã khuyến mãi và số tiền phải trả cho chi tiết đơn hàng
    SELECT @ThanhTien = GiaNiemYet * @SoLuongGiam
    FROM SANPHAM
    WHERE MaSP = @MaSP;

    SET @TienPhaiTra = @ThanhTien * (1 - @TiLe);

    UPDATE CTDONHANG WITH (XLOCK)
    SET MaKhuyenMai = @MaKhuyenMai,
        TienPhaiTra = @TienPhaiTra
    WHERE MaDH = @MaDH AND STT = @STT;

    -- 2.3. Cập nhật lại số lượng đã sử dụng mã khuyến mãi
    UPDATE KHUYENMAI WITH (XLOCK)
    SET SLDaBan = SLDaBan + @SoLuongGiam
    WHERE MaKhuyenMai = @MaKhuyenMai;

    -- 2.4. Kiểm tra và cập nhật tình trạng của mã khuyến mãi nếu hết hiệu lực
    EXEC sp_KiemTraSoLuongDaBanKM @MaKhuyenMai;

    COMMIT TRANSACTION;
END;
GO
-----------------sp_CapNhatTongGiaTriDonHang---------------
CREATE OR ALTER PROCEDURE sp_CapNhatTongGiaTriDonHang
    @MaDH INT -- Mã đơn hàng
AS
BEGIN
    BEGIN TRANSACTION;

    -- Đặt mức độ cô lập giao dịch là REPEATABLE READ
    SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;

    -- 1. Tính tổng thành tiền và tổng tiền phải trả cho tất cả các chi tiết đơn hàng
    DECLARE @TongThanhTien INT, @TongPhaiTra INT;
    SELECT @TongThanhTien = SUM(ThanhTien), 
           @TongPhaiTra = SUM(TienPhaiTra)
    FROM CTDONHANG WITH (SERIALIZABLE)
    WHERE MaDH = @MaDH;

    -- 2. Kiểm tra khách hàng có sở hữu phiếu mua hàng hợp lệ không
    DECLARE @MaKH INT, @TriGia INT = 0, @MaPhieu INT = NULL;
    SELECT @MaKH = MaKH
    FROM DONHANG
    WHERE MaDH = @MaDH;

    IF @MaKH IS NOT NULL
    BEGIN
        -- Gọi sp_ApDungPhieuMuaHang để kiểm tra và áp dụng phiếu mua hàng
        EXEC sp_ApDungPhieuMuaHang @MaKH, @TriGia OUTPUT, @MaPhieu OUTPUT;
    END

    -- 3. Nếu tồn tại phiếu mua hàng hợp lệ thì áp dụng giảm giá vào tổng tiền phải trả
    IF @TriGia > 0
    BEGIN
        SET @TongPhaiTra = @TongPhaiTra - @TriGia;
        IF @TongPhaiTra < 0 
        BEGIN
            SET @TongPhaiTra = 0; -- Đảm bảo tổng tiền không âm
        END
    END

    -- 4. Cập nhật tổng thành tiền, tổng tiền phải trả và mã phiếu mua hàng áp dụng trong bảng Đơn hàng
    UPDATE DONHANG WITH (XLOCK)
    SET ThanhTien = @TongThanhTien,
        TongPhaiTra = @TongPhaiTra,
        MaPhieu = @MaPhieu
    WHERE MaDH = @MaDH;

    COMMIT TRANSACTION;
END;
GO

----------------sp_XacDinhKMChoSP---------------------------------
CREATE OR ALTER PROCEDURE sp_XacDinhKMChoSP
    @MaSP INT,         -- Mã sản phẩm
    @MaDH INT,         -- Mã đơn hàng
    @MaKhuyenMai INT OUTPUT, -- Mã khuyến mãi (Output)
    @SoLuongConLai INT OUTPUT -- Số lượng còn lại của khuyến mãi (Output)
AS
BEGIN
    -- Đặt giá trị mặc định ban đầu
    SET @MaKhuyenMai = NULL;
    SET @SoLuongConLai = 0;

    BEGIN TRANSACTION;

    -- 1. Kiểm tra khuyến mãi Combo Sale
    SELECT TOP 1 @MaKhuyenMai = KM.MaKhuyenMai, 
                 @SoLuongConLai = (KM.SLToiDa - KM.SLDaBan)
    FROM KHUYENMAI KM WITH (ROWLOCK)
    JOIN COMBOSALE CS WITH (ROWLOCK) ON KM.MaKhuyenMai = CS.MaKhuyenMai
    WHERE KM.TinhTrang = N'Còn hiệu lực'
      AND (CS.MaSP1 = @MaSP OR CS.MaSP2 = @MaSP)
    ORDER BY KM.NgayBatDau;

    IF @MaKhuyenMai IS NOT NULL
    BEGIN
        -- Khóa dòng khuyến mãi được chọn
        UPDATE COMBOSALE WITH (XLOCK)
        SET MaKhuyenMai = MaKhuyenMai
        WHERE MaKhuyenMai = @MaKhuyenMai;

        RETURN;
    END

    -- 2. Kiểm tra khuyến mãi Flash Sale
    SELECT TOP 1 @MaKhuyenMai = KM.MaKhuyenMai, 
                 @SoLuongConLai = (KM.SLToiDa - KM.SLDaBan)
    FROM KHUYENMAI KM WITH (ROWLOCK)
    JOIN FLASHSALE FS WITH (ROWLOCK) ON KM.MaKhuyenMai = FS.MaKhuyenMai
    WHERE KM.TinhTrang = N'Còn hiệu lực'
      AND FS.MaSP = @MaSP
    ORDER BY KM.NgayBatDau;

    IF @MaKhuyenMai IS NOT NULL
    BEGIN
        -- Khóa dòng khuyến mãi được chọn
        UPDATE FLASHSALE WITH (XLOCK)
        SET MaKhuyenMai = MaKhuyenMai
        WHERE MaKhuyenMai = @MaKhuyenMai;

        RETURN;
    END

    -- 3. Kiểm tra khuyến mãi Member Sale
    DECLARE @MaKH INT;
    SELECT @MaKH = MaKH
    FROM DONHANG WITH (ROWLOCK)
    WHERE MaDH = @MaDH;

    IF @MaKH IS NOT NULL
    BEGIN
        SELECT TOP 1 @MaKhuyenMai = KM.MaKhuyenMai, 
                     @SoLuongConLai = (KM.SLToiDa - KM.SLDaBan)
        FROM KHUYENMAI KM WITH (ROWLOCK)
        JOIN MEMBERSALE MS WITH (ROWLOCK) ON KM.MaKhuyenMai = MS.MaKhuyenMai
        WHERE KM.TinhTrang = N'Còn hiệu lực'
          AND MS.MaPH = (SELECT MaPH FROM KHACHHANG WHERE MaKH = @MaKH)
        ORDER BY KM.NgayBatDau;

        IF @MaKhuyenMai IS NOT NULL
        BEGIN
            -- Khóa dòng khuyến mãi được chọn
            UPDATE MEMBERSALE WITH (XLOCK)
            SET MaKhuyenMai = MaKhuyenMai
            WHERE MaKhuyenMai = @MaKhuyenMai;

            RETURN;
        END
    END

    COMMIT TRANSACTION;
END;
GO
-----------------sp_KiemTraSoLuongDaBanKM----------------------
CREATE OR ALTER PROCEDURE sp_KiemTraSoLuongDaBanKM
    @MaKM INT -- Mã khuyến mãi
AS
BEGIN
    BEGIN TRANSACTION;

    -- Đặt khóa RowLock để kiểm tra và cập nhật tình trạng khuyến mãi
    DECLARE @SLDaBan INT, @SLToiDa INT;

    -- Lấy thông tin số lượng đã bán và số lượng tối đa từ bảng Khuyến mãi
    SELECT @SLDaBan = SLDaBan, 
           @SLToiDa = SLToiDa
    FROM KHUYENMAI WITH (ROWLOCK)
    WHERE MaKhuyenMai = @MaKM;

    -- Kiểm tra nếu số lượng đã bán >= số lượng tối đa
    IF @SLDaBan >= @SLToiDa
    BEGIN
        -- Cập nhật trạng thái khuyến mãi thành "Kết thúc"
        UPDATE KHUYENMAI WITH (ROWLOCK)
        SET TinhTrang = N'Kết thúc'
        WHERE MaKhuyenMai = @MaKM;
    END

    COMMIT TRANSACTION;
END;
GO
-----------------sp_ApDungPhieuMuaHang------------
CREATE OR ALTER PROCEDURE sp_ApDungPhieuMuaHang
    @MaKH INT,          -- Mã khách hàng
    @TriGia INT OUTPUT, -- Giá trị phiếu mua hàng (Output)
    @MaPhieu INT OUTPUT -- Mã phiếu mua hàng (Output)
AS
BEGIN
    BEGIN TRANSACTION;

    -- 1. Kiểm tra MaKH có phiếu mua hàng có trạng thái là "Chưa sử dụng"
    DECLARE @TrangThai NVARCHAR(15), @HanSuDung DATETIME, @MaLP INT;

    SELECT TOP 1 @MaPhieu = MaPhieu,
                 @MaLP = MaLP,
                 @TrangThai = TrangThai,
                 @HanSuDung = HanSuDung
    FROM PHIEUMUAHANG WITH (ROWLOCK)
    WHERE MaKH = @MaKH 
      AND TrangThai = N'Chưa sử dụng'
      AND HanSuDung >= GETDATE()
    ORDER BY NgayTang;

    IF @MaPhieu IS NULL
    BEGIN
        -- Nếu không có phiếu hợp lệ, thoát
        PRINT 'Không có phiếu mua hàng hợp lệ.';
        SET @TriGia = 0;
        ROLLBACK TRANSACTION;
        RETURN;
    END

    -- 1.1. Lấy giá trị phiếu mua hàng từ bảng LOAIPHIEUMUAHANG
    SELECT @TriGia = TriGia
    FROM LOAIPHIEUMUAHANG
    WHERE MaLP = @MaLP;

    -- 1.2. Cập nhật lại trạng thái của phiếu mua hàng là "Đã sử dụng"
    UPDATE PHIEUMUAHANG WITH (XLOCK)
    SET TrangThai = N'Đã sử dụng'
    WHERE MaPhieu = @MaPhieu;

    -- 1.3. Trả ra trị giá và mã phiếu
    PRINT 'Phiếu mua hàng đã được áp dụng.';

    COMMIT TRANSACTION;
END;

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




