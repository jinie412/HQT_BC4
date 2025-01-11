USE HQT
GO

INSERT INTO PHANHANG (TenPH, TongMin, TongMax) VALUES
(N'Kim Cương', 50000000, NULL),
(N'Bạch Kim', 30000000, 49999999),
(N'Vàng', 15000000, 29999999),
(N'Bạc', 5000000, 14999999),
(N'Đồng', 1000000, 4999999),
(N'Thân Thiết', 0, 999999);

INSERT INTO DANHMUC (TenDM) VALUES
(N'Điện tử'),
(N'Gia dụng'),
(N'Thời trang'),
(N'Thực phẩm'),
(N'Đồ chơi trẻ em'),
(N'Sách vở'),
(N'Phụ kiện'),
(N'Thiết bị y tế'),
(N'Nội thất'),
(N'Đồ dùng học tập');

INSERT INTO BOPHAN (TenBP) VALUES
(N'Chăm sóc khách hàng'),
(N'Quản lý ngành hàng'),
(N'Xử lý đơn hàng'),
(N'Quản lý kho hàng'),
(N'Kinh doanh'),
(N'Nhân sự'),
(N'Tài chính'),
(N'Marketing'),
(N'IT hỗ trợ'),
(N'An ninh');


INSERT INTO NHANVIEN (HoTen, DiaChi, GioiTinh, SDT, CCCD, MaBP) VALUES
(N'Nguyễn Văn A', N'Tp.HCM', N'Nam', '0901234567', '123456789012', 1),
(N'Trần Thị B', N'Tp.HCM', N'Nữ', '0912345678', '987654321098', 2),
(N'Lê Văn C', N'Hà Nội', N'Nam', '0934567890', '456789123456', 3),
(N'Phạm Thị D', N'Tp.HCM', N'Nữ', '0909876543', '123789456123', 4),
(N'Huỳnh Văn E', N'Tp.HCM', N'Nam', '0904567890', '789123456789', 5),
(N'Ngô Thị F', N'Đà Nẵng', N'Nữ', '0913456789', '456123789456', 6),
(N'Võ Văn G', N'Hải Phòng', N'Nam', '0921234567', '987321654987', 7),
(N'Đỗ Thị H', N'Cần Thơ', N'Nữ', '0936789012', '321654987321', 8),
(N'Nguyễn Văn I', N'Nha Trang', N'Nam', '0945678901', '654789321654', 9),
(N'Phan Thị K', N'Vũng Tàu', N'Nữ', '0956789012', '789654123789', 10);

INSERT INTO KHACHHANG (SDT, HoTen, DiaChi, NgaySinh, NgayDangKy, MaPH, MaNV) VALUES
('0961234567', N'Nguyễn Thị D', N'Tp.HCM', '1990-01-01', '2022-01-01', 1, 1),
('0952345678', N'Lê Văn E', N'Hà Nội', '1985-01-05', '2022-02-15', 2, 2),
('0943456789', N'Trần Thị F', N'Tp.HCM', '1992-01-10', '2022-03-01', 3, 3),
('0934567890', N'Phạm Văn G', N'Cần Thơ', '1988-01-15', '2022-04-01', 4, 4),
('0925678901', N'Huỳnh Thị H', N'Nha Trang', '1995-01-20', '2022-05-01', 5, 5),
('0916789012', N'Ngô Văn I', N'Tp.HCM', '1990-01-25', '2022-06-01', 6, 6),
('0907890123', N'Võ Thị J', N'Hải Phòng', '1987-01-22', '2022-07-01', 1, 7),
('0988901234', N'Đỗ Văn K', N'Tp.HCM', '1993-08-05', '2022-08-01', 2, 8),
('0979012345', N'Phan Thị L', N'Hà Nội', '1996-09-10', '2022-09-01', 3, 9),
('0960123456', N'Lê Văn M', N'Đà Nẵng', '1989-10-15', '2022-10-01', 4, 10);

INSERT INTO NHASANXUAT (TenNSX, SDT, DiaChi) VALUES
(N'Samsung', '0987654321', N'Hàn Quốc'), -- Điện tử
(N'Panasonic', '0911223344', N'Nhật Bản'), -- Gia dụng
(N'Vinatex', '0933445566', N'Việt Nam'), -- Thời trang
(N'Vinamilk', '0922334455', N'Việt Nam'), -- Thực phẩm
(N'Lego', '0911445566', N'Đan Mạch'), -- Đồ chơi trẻ em
(N'Nhà sách Fahasa', '0988112233', N'Việt Nam'), -- Sách vở
(N'Phụ kiện Anker', '0977334455', N'Mỹ'), -- Phụ kiện
(N'Medical Plus', '0955667788', N'Đức'), -- Thiết bị y tế
(N'Nội thất Hòa Phát', '0966112233', N'Việt Nam'), -- Nội thất
(N'Thế giới học tập', '0988776655', N'Việt Nam'); -- Đồ dùng học tập


INSERT INTO SANPHAM (TenSP, MoTa, GiaNiemYet, SLToiDa, SLTonKho, DonVi, NgayThem, NgayCapNhat, MaDM, MaNSX) VALUES
-- Điện tử
(N'TV Samsung QLED', N'TV QLED 4K UHD', 20000000, 50, 25, N'Cái', '2024-01-01', '2024-01-10', 1, 1),
(N'Samsung Galaxy S23', N'Di động cao cấp', 25000000, 100, 78, N'Cái', '2024-01-02', '2024-01-10', 1, 1),
(N'Laptop Samsung Galaxy Book', N'Laptop siêu mỏng', 30000000, 30, 25, N'Cái', '2024-01-03', '2024-01-10', 1, 1),
(N'Tai nghe Samsung Buds', N'Tai nghe không dây', 5000000, 200, 180, N'Cái', '2024-01-04', '2024-01-10', 1, 1),
(N'Điều hòa Samsung WindFree', N'Điều hòa tiết kiệm điện', 15000000, 50, 35, N'Cái', '2024-01-05', '2024-01-10', 1, 1),

-- Gia dụng
(N'Tủ lạnh Panasonic', N'Tủ lạnh Inverter', 12000000, 50, 25, N'Cái', '2024-01-06', '2024-01-10', 2, 2),
(N'Máy giặt Panasonic', N'Máy giặt cửa trước', 9000000, 40, 20, N'Cái', '2024-01-07', '2024-01-10', 2, 2),
(N'Lò vi sóng Panasonic', N'Lò vi sóng điện tử', 4000000, 30, 27, N'Cái', '2024-01-08', '2024-01-10', 2, 2),
(N'Nồi cơm Panasonic', N'Nồi cơm cao tần', 3000000, 100, 80, N'Cái', '2024-01-09', '2024-01-10', 2, 2),
(N'Máy hút bụi Panasonic', N'Máy hút bụi công suất lớn', 7000000, 20, 16, N'Cái', '2024-01-10', '2024-01-10', 2, 2),

-- Thời trang
(N'Áo sơ mi Vinatex', N'Áo sơ mi cotton', 300000, 500, 300, N'Cái', '2024-01-11', '2024-01-10', 3, 3),
(N'Quần jean Vinatex', N'Quần jean thời trang', 500000, 400, 375, N'Cái', '2024-01-12', '2024-01-10', 3, 3),
(N'Áo khoác Vinatex', N'Áo khoác gió', 700000, 300, 240, N'Cái', '2024-01-13', '2024-01-10', 3, 3),
(N'Dép Vinatex', N'Dép đi trong nhà', 200000, 200, 170, N'Đôi', '2024-01-14', '2024-01-10', 3, 3),
(N'Mũ lưỡi trai Vinatex', N'Mũ thời trang', 150000, 100, 90, N'Cái', '2024-01-15', '2024-01-10', 3, 3),

-- Thực phẩm
(N'Sữa Vinamilk', N'Sữa tươi nguyên chất', 30000, 1000, 500, N'Hộp', '2024-01-16', '2024-01-10', 4, 4),
(N'Yogurt Vinamilk', N'Sữa chua hộp 100g', 5000, 2000, 1800, N'Hộp', '2024-01-17', '2024-01-10', 4, 4),
(N'Bánh Vinamilk', N'Bánh quy bơ sữa', 150000, 500, 480, N'Hộp', '2024-01-18', '2024-01-10', 4, 4),
(N'Kem Vinamilk', N'Kem hộp 1L', 50000, 300, 280, N'Hộp', '2024-01-19', '2024-01-10', 4, 4),
(N'Sữa đặc Vinamilk', N'Sữa đặc hộp 1L', 40000, 600, 450, N'Hộp', '2024-01-20', '2024-01-10', 4, 4),

-- Lego products
(N'Bộ Lego Classic', N'Lego xây dựng cơ bản', 1000000, 100, 50, N'Hộp', '2024-01-21', '2024-01-30', 5, 5),
(N'Lego City', N'Lego chủ đề thành phố', 1500000, 80, 60, N'Hộp', '2024-01-22', '2024-01-31', 5, 5),
(N'Lego Friends', N'Lego chủ đề bạn bè', 1300000, 90, 50, N'Hộp', '2024-01-23', '2024-02-01', 5, 5),
(N'Lego Technic', N'Lego chủ đề kỹ thuật', 2000000, 70, 50, N'Hộp', '2024-01-24', '2024-02-02', 5, 5),
(N'Lego Star Wars', N'Lego chủ đề Star Wars', 2500000, 60, 50, N'Hộp', '2024-01-25', '2024-02-03', 5, 5),
-- Fahasa products
(N'Sách giáo khoa Fahasa', N'Sách giáo khoa lớp 1', 50000, 200, 100, N'Cuốn', '2024-02-01', '2024-02-10', 6, 6),
(N'Sách văn học Fahasa', N'Truyện ngắn', 70000, 150, 110, N'Cuốn', '2024-02-02', '2024-02-11', 6, 6),
(N'Vở học sinh Fahasa', N'Vở viết 200 trang', 20000, 300, 180, N'Quyển', '2024-02-03', '2024-02-12', 6, 6),
(N'Bút bi Fahasa', N'Bút bi nước', 10000, 500, 420, N'Cây', '2024-02-04', '2024-02-13', 6, 6),
(N'Sách tham khảo Fahasa', N'Sách ôn luyện toán', 90000, 100, 50, N'Cuốn', '2024-02-05', '2024-02-14', 6, 6),

-- Anker products
(N'Sạc dự phòng Anker', N'Sạc dự phòng 10,000mAh', 500000, 100, 50, N'Cái', '2024-02-06', '2024-02-15', 7, 7),
(N'Tai nghe Anker', N'Tai nghe bluetooth', 800000, 80, 60, N'Cái', '2024-02-07', '2024-02-16', 7, 7),
(N'Cáp sạc Anker', N'Cáp sạc USB-C', 200000, 200, 160, N'Cái', '2024-02-08', '2024-02-17', 7, 7),
(N'Loa bluetooth Anker', N'Loa bluetooth mini', 1000000, 50, 40, N'Cái', '2024-02-09', '2024-02-18', 7, 7),
(N'Sạc nhanh Anker', N'Sạc nhanh 45W', 600000, 70, 48, N'Cái', '2024-02-10', '2024-02-19', 7, 7),

-- Medical Plus products
(N'Máy đo huyết áp Medical Plus', N'Máy đo huyết áp điện tử', 1500000, 50, 25, N'Cái', '2024-02-11', '2024-02-20', 8, 8),
(N'Nhiệt kế điện tử Medical Plus', N'Nhiệt kế điện tử hiện đại', 500000, 100, 80, N'Cái', '2024-02-12', '2024-02-21', 8, 8),
(N'Máy tạo oxy Medical Plus', N'Máy tạo oxy gia đình', 12000000, 30, 26, N'Cái', '2024-02-13', '2024-02-22', 8, 8),
(N'Dụng cụ y tế Medical Plus', N'Dụng cụ sơ cứu', 200000, 200, 180, N'Bộ', '2024-02-14', '2024-02-23', 8, 8),
(N'Máy massage Medical Plus', N'Máy massage cầm tay', 1000000, 40, 29, N'Cái', '2024-02-15', '2024-02-24', 8, 8),

-- Hòa Phát products
(N'Bàn học Hòa Phát', N'Bàn học sinh', 1200000, 50, 25, N'Cái', '2024-02-16', '2024-02-25', 9, 9),
(N'Ghế xoay Hòa Phát', N'Ghế văn phòng', 1500000, 60, 50, N'Cái', '2024-02-17', '2024-02-26', 9, 9),
(N'Tủ quần áo Hòa Phát', N'Tủ gỗ công nghiệp', 5000000, 20, 17, N'Cái', '2024-02-18', '2024-02-27', 9, 9),
(N'Kệ sách Hòa Phát', N'Kệ sách gỗ', 2000000, 30, 30, N'Cái', '2024-02-19', '2024-02-28', 9, 9),
(N'Giường ngủ Hòa Phát', N'Giường gỗ công nghiệp', 8000000, 15, 12, N'Cái', '2024-02-20', '2024-03-01', 9, 9),

-- Thế Giới Học Tập products
(N'Bút chì Thế Giới Học Tập', N'Bút chì gỗ', 5000, 500, 250, N'Cây', '2024-02-21', '2024-03-02', 10, 10),
(N'Tập học sinh Thế Giới Học Tập', N'Tập 100 trang', 10000, 400, 375, N'Quyển', '2024-02-22', '2024-03-03', 10, 10),
(N'Hộp bút Thế Giới Học Tập', N'Hộp bút nhựa', 30000, 300, 150, N'Cái', '2024-02-23', '2024-03-04', 10, 10),
(N'Thước kẻ Thế Giới Học Tập', N'Thước kẻ nhựa 30cm', 5000, 500, 370, N'Cây', '2024-02-24', '2024-03-05', 10, 10),
(N'Balo Thế Giới Học Tập', N'Balo học sinh', 200000, 100, 85, N'Cái', '2024-02-25', '2024-03-06', 10, 10);


INSERT INTO LOAIPHIEUMUAHANG (MaPH, TriGia) VALUES
(1, 1200000),  -- Kim Cương
(2, 700000),   -- Bạch Kim
(3, 500000),   -- Vàng
(4, 200000),   -- Bạc
(5, 100000),   -- Đồng
(6, 0);        -- Thân Thiết (không nhận phiếu)

INSERT INTO PHIEUMUAHANG (MaKH, NgayTang, MaLP, MaNV, HanSuDung, TrangThai) VALUES
(1, '2025-01-01', 1, 1, '2025-01-31', N'Chưa sử dụng'),
(2, '2025-01-01', 2, 2, '2025-01-31', N'Đã sử dụng'),
(3, '2025-01-01', 3, 3, '2025-01-31', N'Chưa sử dụng'),
(4, '2025-01-01', 4, 4, '2025-01-31', N'Chưa sử dụng'),
(5, '2025-01-01', 5, 5, '2025-01-31', N'Chưa sử dụng'),
(6, '2025-01-01', 1, 6, '2025-01-31', N'Đã sử dụng'),
(7, '2025-01-01', 2, 7, '2025-01-31', N'Chưa sử dụng'),
(8, '2024-08-01', 3, 8, '2024-08-31', N'Hết hạn'),
(9, '2024-09-01', 4, 9, '2024-09-30', N'Hết hạn'),
(10, '2024-10-01', 5, 10, '2024-10-31', N'Đã sử dụng');

INSERT INTO DONHANG (NgayDat, NgayGiao, TinhTrang, ThanhTien, TongPhaiTra, MaPhieu, MaNV, MaKH) VALUES
('2024-01-01', '2024-01-05', N'Đã giao', 1500000, 1400000, NULL, 1, 1),
('2025-01-02', '2025-01-03', N'Đã giao', 2000000, 1800000, 2, 2, 2),
('2024-03-01', '2024-03-05', N'Đã giao', 3000000, 2800000, NULL, 3, 3),
('2024-04-01', '2024-04-10', N'Đã giao', 2500000, 2300000, NULL, 4, 4),
('2024-05-01', '2024-05-06', N'Đã giao', 1200000, 1100000, NULL, 5, 5),
('2025-01-05', '2024-01-05', N'Đã giao', 5000000, 4700000, 6, 6, 6),
('2024-07-01', '2024-07-06', N'Đã giao', 800000, 750000, NULL, 7, 7),
('2024-07-01', '2024-07-05', N'Đã giao', 900000, 850000, NULL, 8, 8),
('2024-08-01', '2024-08-10', N'Đã giao', 3000000, 3000000, NULL, 9, 9),
('2024-10-01', '2024-10-06', N'Đã giao', 1500000, 1400000, 10, 9, 10);

INSERT INTO KHUYENMAI (NgayBatDau, NgayKetThuc, NgayTaoMaKM, TiLe, SLToiDa, TinhTrang, SLDaBan, LoaiKM, MaNV) VALUES
('2025-01-07', '2025-01-12', '2025-01-07', 10, 50, N'Đang diễn ra', 20, N'Flash-sale', 1),
('2024-01-05', '2024-01-15', '2024-01-05', 15, 30, N'Kết thúc', 30, N'Flash-sale', 2),
('2025-01-06', '2025-01-13', '2025-01-06', 20, 20, N'Đang diễn ra', 10, N'Combo-sale', 3),
('2025-01-08', '2025-01-14', '2025-01-08', 25, 25, N'Đang diễn ra', 15, N'Member-sale', 4),
('2025-01-05', '2025-01-15', '2025-01-05', 5, 100, N'Đang diễn ra', 50, N'Flash-sale', 5),
('2024-02-05', '2024-02-15', '2024-02-05', 10, 40, N'Kết thúc', 40, N'Flash-sale', 1),
('2025-01-06', '2025-01-16', '2025-01-06', 15, 30, N'Đang diễn ra', 20, N'Combo-sale', 2),
('2025-01-07', '2025-01-17', '2025-01-07', 20, 50, N'Đang diễn ra', 30, N'Member-sale', 3),
('2025-01-04', '2025-01-20', '2025-01-04', 30, 60, N'Đang diễn ra', 40, N'Flash-sale', 4),
('2024-03-05', '2024-03-15', '2024-03-05', 35, 50, N'Kết thúc', 50, N'Combo-sale', 5),
('2025-01-08', '2025-01-19', '2025-01-08', 20, 100, N'Đang diễn ra', 70, N'Member-sale', 1),
('2025-01-06', '2025-01-18', '2025-01-06', 10, 40, N'Đang diễn ra', 20, N'Flash-sale', 2),
('2025-01-05', '2025-01-21', '2025-01-05', 25, 50, N'Đang diễn ra', 35, N'Combo-sale', 3),
('2024-04-05', '2024-04-15', '2024-04-05', 30, 60, N'Kết thúc', 50, N'Member-sale', 4),
('2025-01-07', '2025-01-16', '2025-01-07', 20, 50, N'Đang diễn ra', 40, N'Flash-sale', 5),
('2025-01-06', '2025-01-18', '2025-01-06', 15, 30, N'Đang diễn ra', 20, N'Combo-sale', 1),
('2025-01-07', '2025-01-19', '2025-01-07', 25, 40, N'Đang diễn ra', 30, N'Member-sale', 2),
('2025-01-05', '2025-01-17', '2025-01-05', 10, 100, N'Đang diễn ra', 80, N'Flash-sale', 3),
('2025-01-06', '2025-01-20', '2025-01-06', 20, 60, N'Đang diễn ra', 40, N'Combo-sale', 4),
('2025-01-08', '2025-01-22', '2025-01-08', 30, 40, N'Đang diễn ra', 30, N'Member-sale', 5),
('2024-06-05', '2024-06-15', '2024-06-05', 35, 50, N'Kết thúc', 50, N'Flash-sale', 1),
('2025-01-05', '2025-01-18', '2025-01-05', 20, 30, N'Đang diễn ra', 20, N'Combo-sale', 2),
('2025-01-07', '2025-01-19', '2025-01-07', 25, 50, N'Đang diễn ra', 30, N'Member-sale', 3),
('2025-01-06', '2025-01-16', '2025-01-06', 10, 60, N'Đang diễn ra', 40, N'Flash-sale', 4),
('2025-01-07', '2025-01-17', '2025-01-07', 15, 40, N'Đang diễn ra', 30, N'Combo-sale', 5),
('2025-01-05', '2025-01-20', '2025-01-05', 30, 50, N'Đang diễn ra', 40, N'Member-sale', 1),
('2024-08-01', '2024-08-10', '2024-08-01', 25, 70, N'Kết thúc', 70, N'Flash-sale', 2),
('2025-01-06', '2025-01-18', '2025-01-06', 20, 40, N'Đang diễn ra', 20, N'Combo-sale', 3),
('2025-01-07', '2025-01-19', '2025-01-07', 15, 50, N'Đang diễn ra', 30, N'Member-sale', 4),
('2025-01-05', '2025-01-17', '2025-01-05', 10, 100, N'Đang diễn ra', 80, N'Flash-sale', 5);



INSERT INTO CTDONHANG (MaDH, STT, MaSP, SoLuong, ThanhTien, MaKhuyenMai, TienPhaiTra) VALUES
(1, 1, 1, 1, 1500000, NULL, 1400000),
(1, 2, 2, 1, 1500000, 1, 1400000),
(2, 1, 3, 2, 4000000, NULL, 3600000),
(3, 1, 4, 1, 2500000, 2, 2300000),
(3, 2, 5, 1, 2500000, NULL, 2300000),
(4, 1, 6, 3, 9000000, NULL, 8700000),
(5, 1, 7, 2, 6000000, NULL, 5800000),
(5, 2, 8, 1, 3000000, 3, 2800000),
(6, 1, 9, 1, 4500000, NULL, 4200000),
(6, 2, 10, 1, 5000000, NULL, 4700000),
(7, 1, 11, 5, 1500000, NULL, 1400000),
(7, 2, 12, 2, 1000000, 4, 950000),
(8, 1, 13, 4, 200000, NULL, 180000),
(9, 1, 14, 2, 2000000, NULL, 2000000),
(10, 1, 15, 3, 3000000, NULL, 2700000);

INSERT INTO FLASHSALE (MaKhuyenMai, MaSP) VALUES
(1, 1), 
(2, 2), 
(5, 3), 
(6, 4), 
(9, 5), 
(12, 6), 
(15, 7), 
(18, 8), 
(24, 9), 
(30, 10);


INSERT INTO COMBOSALE (MaKhuyenMai, MaSP1, MaSP2) VALUES
(3, 1, 2),
(7, 3, 4),
(10, 5, 6),
(13, 7, 8),
(16, 9, 10),
(19, 11, 12),
(22, 13, 14),
(25, 15, 16),
(28, 17, 18),
(29, 19, 20);


INSERT INTO MEMBERSALE (MaKhuyenMai, MaPH) VALUES
(4, 1), 
(8, 2), 
(11, 3), 
(14, 4), 
(17, 5), 
(20, 1), 
(23, 2), 
(26, 3), 
(27, 4), 
(29, 5);

INSERT INTO DONDATNSX (MaNSX, SoLuong, MaSP, NgayDat, TinhTrang, MaNV) VALUES
-- Chưa giao
(1, 20, 1, '2025-01-05', N'Chưa giao', 1),
(2, 15, 6, '2025-01-03', N'Chưa giao', 2),
(3, 50, 11, '2025-01-04', N'Chưa giao', 3),
(4, 100, 16, '2025-01-02', N'Chưa giao', 4),
(5, 10, 21, '2025-01-08', N'Chưa giao', 5),
(6, 20, 26, '2025-01-06', N'Chưa giao', 6),
(7, 30, 31, '2025-01-07', N'Chưa giao', 7),
(8, 25, 36, '2025-01-01', N'Chưa giao', 8),
(9, 12, 41, '2025-01-03', N'Chưa giao', 9),
(10, 150, 46, '2025-01-04', N'Chưa giao', 10),
-- Đã giao
(1, 15, 2, '2024-11-10', N'Đã giao', 1),
(2, 30, 7, '2024-12-01', N'Đã giao', 2),
(3, 50, 12, '2024-11-15', N'Đã giao', 3),
(4, 100, 17, '2024-12-20', N'Đã giao', 4),
(5, 20, 22, '2024-11-25', N'Đã giao', 5),
(6, 10, 27, '2024-12-10', N'Đã giao', 6),
(7, 30, 32, '2024-12-15', N'Đã giao', 7),
(8, 25, 37, '2024-12-22', N'Đã giao', 8),
(9, 12, 42, '2024-11-30', N'Đã giao', 8),
(10, 20, 47, '2024-12-25', N'Đã giao', 10);


INSERT INTO DONNHANHANG (MaNV, NgayNhan, TongTien, MaNSX) VALUES
(1, '2024-11-15', 375000000, 1),
(2, '2024-12-05', 450000000, 2),
(3, '2024-11-20', 500000000, 3),
(4, '2024-12-25', 250000000, 4),
(5, '2024-11-30', 300000000, 5),
(6, '2024-12-15', 90000000, 6),
(7, '2024-12-20', 240000000, 7),
(8, '2024-12-30', 300000000, 8),
(9, '2024-12-05', 180000000, 9),
(10, '2024-12-30', 200000000, 10);


INSERT INTO CTDONNHANHANG (STT, MaDNH, SoLuong, DonGia, ThanhTien, MaDDH) VALUES
(1, 1, 15, 25000000, 375000000, 11),
(1, 2, 30, 15000000, 450000000, 12),
(1, 3, 50, 10000000, 500000000, 13),
(1, 4, 100, 2500000, 250000000, 14),
(1, 5, 20, 15000000, 300000000, 15),
(1, 6, 10, 9000000, 90000000, 16),
(1, 7, 30, 8000000, 240000000, 17),
(1, 8, 25, 12000000, 300000000, 18),
(1, 9, 12, 15000000, 180000000, 19),
(1, 10, 20, 10000000, 200000000, 20);