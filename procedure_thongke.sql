USE HQT 
GO



CREATE OR ALTER PROCEDURE sp_LietKeSanPhamTheoSoLuongBan(
    @NgayBatDau DATETIME,
    @NgayKetThuc DATETIME)
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
    FROM DonHang DH WITH (HOLDLOCK)
    INNER JOIN CTDonHang CT WITH (HOLDLOCK) ON DH.MaDH = CT.MaDH
    INNER JOIN SanPham SP ON CT.MASP = SP.MaSP 
    WHERE DH.NgayGiao BETWEEN @NgayBatDau AND @NgayKetThuc
    GROUP BY CT.MaSP, SP.TenSP;

    -- 2. Lấy thông tin sản phẩm đã bán và sắp xếp theo số lượng bán được giảm dần
    SELECT MaSanPham, TenSanPham, SoLuongBan
    FROM #DanhSachSanPham
    ORDER BY SoLuongBan DESC;

    -- Xóa bảng tạm
    DROP TABLE #DanhSachSanPham;

    -- Kết thúc giao dịch
    COMMIT;
END;

EXEC sp_LietKeSanPhamTheoSoLuongBan @NgayBatDau = '2024-01-01',@NgayKetThuc = '2025-01-01'

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