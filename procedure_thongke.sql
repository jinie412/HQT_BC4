USE HQT 
GO

--Liet ke san pham theo sl ban
CREATE OR ALTER PROCEDURE sp_LietKeSanPhamTheoSoLuongBan(
    @NgayBatDau DATETIME,
    @NgayKetThuc DATETIME
)
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    -- Tạo bảng tạm để lưu danh sách sản phẩm
    CREATE TABLE #DanhSachSanPham (
        MaSanPham INT,
        TenSanPham NVARCHAR(255),
        SoLuongBan INT
    );

    -- 1. Truy xuất các đơn hàng nằm trong khoảng thời gian từ NgayBatDau đến NgayKetThuc
    INSERT INTO #DanhSachSanPham (MaSanPham, TenSanPham, SoLuongBan)
    SELECT
        CT.MaSP,
        SP.TenSP,
        SUM(CT.SoLuong) AS SoLuongBan
    FROM DonHang DH
    INNER JOIN CTDonHang CT ON DH.MaDH = CT.MaDH
    INNER JOIN SanPham SP ON CT.MaSP = SP.MaSP 
    WHERE DH.NgayGiao BETWEEN @NgayBatDau AND @NgayKetThuc
    GROUP BY CT.MaSP, SP.TenSP;

    -- 2. Lấy thông tin sản phẩm đã bán và sắp xếp theo số lượng bán được giảm dần
    SELECT MaSanPham, TenSanPham, SoLuongBan
    FROM #DanhSachSanPham
    ORDER BY SoLuongBan DESC;

    -- Xóa bảng tạm sau khi lấy kết quả
    DROP TABLE #DanhSachSanPham;

    -- Kết thúc giao dịch
    COMMIT;
END;


EXEC sp_LietKeSanPhamTheoSoLuongBan @NgayBatDau = '2024-01-01',@NgayKetThuc = '2025-01-01'

--Tinh tổng khách hàng và doanh thu trong ngày 
CREATE OR ALTER PROCEDURE sp_TinhTongKhachHang_DoanhThuNgay
    @NgayGiao DATETIME
AS
BEGIN
    -- Bắt đầu giao dịch
    BEGIN TRANSACTION;
    
    DECLARE @TongLuongKhach INT;
    DECLARE @TongDoanhThu INT;

    -- Tính tổng số lượng khách hàng
    SELECT @TongLuongKhach = COUNT(DISTINCT MaKH)
    FROM DONHANG
    WHERE NgayGiao = @NgayGiao;

    -- Tính tổng doanh thu
    SELECT @TongDoanhThu = SUM(TongPhaiTra)
    FROM DONHANG
    WHERE NgayGiao = @NgayGiao;

    -- In kết quả ra để kiểm tra
    SELECT @TongLuongKhach AS TongLuongKhach, @TongDoanhThu AS TongDoanhThu;

    -- Cam kết giao dịch
    COMMIT;
END
GO

EXEC sp_TinhTongKhachHang_DoanhThuNgay @NgayGiao = '2024-05-06'

CREATE OR ALTER PROCEDURE sp_ThongKeSanPhamTheoNgay
    @Ngay Date,
    @MaSP INT,
    @SoLuongDaBan INT OUTPUT,
    @SoLuongKhachHang INT OUTPUT
AS
BEGIN
    -- Tính toán số lượng sản phẩm đã bán trong ngày
    SELECT @SoLuongDaBan = COUNT(*)
    FROM CTDONHANG dh
    JOIN DONHANG h ON dh.MaDH = h.MaDH
    WHERE dh.MaSP = @MaSP AND h.NgayDat = @Ngay;

    -- Tính toán số lượng khách hàng đã mua sản phẩm này trong ngày
    SELECT @SoLuongKhachHang = COUNT(DISTINCT h.MaKH)
    FROM CTDONHANG dh
    JOIN DONHANG h ON dh.MaDH = h.MaDH
    WHERE dh.MaSP = @MaSP AND h.NgayDat = @Ngay;
END;

CREATE OR ALTER PROCEDURE sp_ThongKeTatCacSanPhamTheoNgay
    @Ngay Date
AS
BEGIN
    -- Tạo bảng tạm để lưu kết quả thống kê
    CREATE TABLE #ThongKeKetQua (
        MaSP INT,
        TenSP NVARCHAR(255),  -- Thêm cột tên sản phẩm
        SoLuongDaBan INT,
        SoLuongKhachHang INT
    );

    -- Duyệt qua tất cả các sản phẩm đã bán trong ngày và gọi lại thủ tục sp_ThongKeSanPhamTheoNgay
    DECLARE @MaSP INT, @TenSP NVARCHAR(255), @SoLuongDaBan INT, @SoLuongKhachHang INT;
    
    -- Duyệt qua các sản phẩm trong ngày (lấy MaSP từ bảng CTDONHANG)
    DECLARE product_cursor CURSOR FOR
    SELECT DISTINCT dh.MaSP
    FROM CTDONHANG dh
    JOIN DONHANG h ON dh.MaDH = h.MaDH
    WHERE h.NgayDat = @Ngay;

    OPEN product_cursor;
    FETCH NEXT FROM product_cursor INTO @MaSP;

    -- Lặp lại cho mỗi sản phẩm
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Lấy tên sản phẩm từ bảng SANPHAM
        SELECT @TenSP = TenSP
        FROM SANPHAM
        WHERE MaSP = @MaSP;

        -- Gọi thủ tục sp_ThongKeSanPhamTheoNgay để lấy thông tin cho sản phẩm hiện tại
        EXEC sp_ThongKeSanPhamTheoNgay @Ngay, @MaSP, @SoLuongDaBan OUTPUT, @SoLuongKhachHang OUTPUT;

        -- Lưu kết quả vào bảng tạm
        INSERT INTO #ThongKeKetQua (MaSP, TenSP, SoLuongDaBan, SoLuongKhachHang)
        VALUES (@MaSP, @TenSP, @SoLuongDaBan, @SoLuongKhachHang);

        -- Lấy sản phẩm tiếp theo
        FETCH NEXT FROM product_cursor INTO @MaSP;
    END;

    CLOSE product_cursor;
    DEALLOCATE product_cursor;

    -- Trả về kết quả thống kê
    SELECT * FROM #ThongKeKetQua;

    -- Xóa bảng tạm
    DROP TABLE #ThongKeKetQua;
END;

exec sp_ThongKeTatCacSanPhamTheoNgay @Ngay = '2024-08-01'

