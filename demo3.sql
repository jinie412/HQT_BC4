--TÌNH HUỐNG: Khi nhân viên đang tiến hành cập nhật cho một đơn hàng thì có một giao tác áp dụng mã khuyến mãi vào 


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

    SET @TienPhaiTra = @ThanhTien * ((100 - @TiLe)/100);

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
    WAITFOR DELAY '00:00:03'
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
    FROM CTDONHANG WITH (ROWLOCK)
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
    WAITFOR DELAY '00:00:10'
    COMMIT TRANSACTION;
END;
GO