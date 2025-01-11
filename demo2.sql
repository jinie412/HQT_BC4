-- TÌNH HUỐNG: Khi nhân viên đang tiến hành áp dụng khuyến mãi cho một sản phẩm thì nhân viên khác tiến hành thêm một khuyến mại mới trên bảng. Kịch bản như sau: 
-- Transaction 1 thực hiện sp_ApDungKhuyenMai để áp dụng mã khuyến mãi cho sản phẩm:
--   Tìm kiếm mã khuyến mãi phù hợp.
--   Cập nhật số lượng sử dụng.
--Transaction 2 thực hiện sp_ThemKhuyenMai:
--   Thêm một mã khuyến mãi mới vào bảng KHUYENMAI

--Phantom Read: T1 đọc dữ liệu từ bảng KHUYENMAI trước khi T2 thêm mã mới. 
--Vì không có khóa, dữ liệu mới xuất hiện nhưng không được tính trong kiểm tra ban đầu của T1.
--> T1 áp dụng mã khuyến mãi mà không bao gồm trạng thái cập nhật từ T2.
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
        
        INSERT INTO KHUYENMAI (
            NgayBatDau, NgayKetThuc, NgayTaoMaKM, TiLe, SLToiDa, TinhTrang, SLDaBan, LoaiKM, MaNV
        )
        VALUES (
            @NgayBatDau, @NgayKetThuc, GETDATE(), @TiLe, @SLToiDa, N'Đang diễn ra', 0, @LoaiKM, @MaNV
        );

        DECLARE @MaKhuyenMai INT;
        SELECT @MaKhuyenMai = SCOPE_IDENTITY();

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


CREATE OR ALTER PROCEDURE sp_ApDungKhuyenMai
    @MaDH INT,       
    @STT INT,         
    @MaSP INT,        
    @SoLuong INT      
AS
BEGIN
    BEGIN TRANSACTION;

    DECLARE @MaKhuyenMai INT, @TiLe FLOAT, @SLToiDa INT, @SLDaBan INT;
    SELECT TOP 1 @MaKhuyenMai = MaKhuyenMai, 
                 @TiLe = TiLe, 
                 @SLToiDa = SLToiDa, 
                 @SLDaBan = SLDaBan
    FROM KHUYENMAI
    WHERE TinhTrang = N'Đang diễn ra'
      AND NgayBatDau <= GETDATE()
      AND NgayKetThuc >= GETDATE();

    IF @MaKhuyenMai IS NULL
    BEGIN
        PRINT 'Không có mã khuyến mãi hợp lệ';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF @SLDaBan >= @SLToiDa
    BEGIN
        PRINT 'Mã khuyến mãi đã hết số lượng áp dụng';
        ROLLBACK TRANSACTION;
        RETURN;
    END

    DECLARE @SoLuongGiam INT, @ThanhTien INT, @TienPhaiTra INT;
    SET @SoLuongGiam = CASE
        WHEN @SLDaBan + @SoLuong <= @SLToiDa THEN @SoLuong
        ELSE @SLToiDa - @SLDaBan
    END;

    SELECT @ThanhTien = GiaNiemYet * @SoLuongGiam
    FROM SANPHAM
    WHERE MaSP = @MaSP;

   SET @TienPhaiTra = @ThanhTien * ((100 - @TiLe)/100);

    UPDATE CTDONHANG
    SET MaKhuyenMai = @MaKhuyenMai,
        TienPhaiTra = @TienPhaiTra
    WHERE MaDH = @MaDH AND STT = @STT;

    UPDATE KHUYENMAI
    SET SLDaBan = SLDaBan + @SoLuongGiam
    WHERE MaKhuyenMai = @MaKhuyenMai;

    EXEC sp_KiemTraSoLuongDaBanKM @MaKhuyenMai;

    COMMIT TRANSACTION;
END;
GO
