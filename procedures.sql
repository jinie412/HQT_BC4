
----------- BỘ PHẬN CHĂM SÓC KHÁCH HÀNG
----------- BỘ PHẬN QUẢN LÝ NGÀNH HÀNG
----------------------------- sp_ThemSanPham -------------------------------------
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

        DECLARE @MaSP INT;
        SELECT @MaSP = ISNULL(MAX(MaSP), 0) + 1 FROM SANPHAM;

        INSERT INTO SANPHAM (MaSP, TenSP, MoTa, GiaNiemYet, SLToiDa, SLTonKho, DonVi, NgayThem, NgayCapNhat, MaDM, MaNSX)
        VALUES (@MaSP, @TenSP, @MoTa, @GiaNiemYet, @SLToiDa, @SLTonKho, @DonVi, GETDATE(), GETDATE(), @MaDM, @MaNSX);

        PRINT N'Sản phẩm mới đã được thêm vào thành công.';
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END
GO

----------------------------- sp_ThemKhuyenMai -------------------------------------
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
        DECLARE @MaKhuyenMai INT;
        SELECT @MaKhuyenMai = ISNULL(MAX(MaKhuyenMai), 0) + 1 FROM KHUYENMAI;

        INSERT INTO KHUYENMAI (MaKhuyenMai, NgayBatDau, NgayKetThuc, NgayTaoMaKM, TiLe, SLToiDa, TinhTrang, SLDaBan, LoaiKM, MaNV)
        VALUES (@MaKhuyenMai, @NgayBatDau, @NgayKetThuc, GETDATE(), @TiLe, @SLToiDa, N'Đang diễn ra', 0, @LoaiKM, @MaNV);

        IF @LoaiKM = N'Combo-sale'
        BEGIN
            INSERT INTO COMBOSALE (MaKhuyenMai, MaSP1, MaSP2)
            VALUES (@MaKhuyenMai, @MaSP1, @MaSP2);
        END
        ELSE IF @LoaiKM = N'Member-sale'
        BEGIN
            INSERT INTO MEMBERSALE (MaKhuyenMai, MaPH)
            VALUES (@MaKhuyenMai, @MaPH);
        END
        ELSE IF @LoaiKM = N'Flash-sale'
        BEGIN
            INSERT INTO FLASHSALE (MaKhuyenMai, MaSP)
            VALUES (@MaKhuyenMai, @MaSP1);
        END;

        PRINT N'Chương trình khuyến mãi đã được thêm thành công.';
    END TRY
    BEGIN CATCH
        PRINT ERROR_MESSAGE();
    END CATCH
END
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
	FROM SANPHAM 
	WHERE MaSP=@MaSP

	SELECT @TONG = SUM(SoLuong)
	FROM DONDATNSX
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
	SELECT @MATT = ISNULL(MAX(MaDDH)+1,1) FROM DONDATNSX

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
        PRINT N'Số lượng giao không hợp lệ hoặc vượt quá số lượng đặt hàng. Đơn hàng không được xử lý.'
    END

    COMMIT TRANSACTION

END
GO


----------- PROCEDURE PHÁT SINH
----------------------------- sp_TaoChiTietDonHang   -------------------------------------
GO
CREATE OR ALTER PROCEDURE sp_TaoChiTietDonHang 
@MaDH INT, @MaSP INT, @SoLuong INT
AS
BEGIN
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






