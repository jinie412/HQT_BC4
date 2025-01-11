-- TÌNH HUỐNG: Một nhân viên đang thực hiện tặng phiếu mua hàng cho khách hàng
-- thì có nhân viên khác đồng thời thực hiện việc cập nhật phân hạng khách hàng

-- 1. Thực hiện tặng phiếu mua hàng cho khách hàng MaKH = 1
BEGIN TRANSACTION
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	DECLARE @MaPH INT,
			@MaLP INT,
			@MaKH INT = 1,
			@MaNV INT = 2
	-- Xem phân hạng khách hàng (Minh họa)
	SELECT *
	FROM KHACHHANG WITH (ROWLOCK)
	WHERE MaKH = @MaKH

	-- Xác định phân hạng khách hàng
	SELECT @MaPH = MaPH
	FROM KHACHHANG WITH (ROWLOCK)
	WHERE MaKH = @MaKH

	WAITFOR DELAY '00:00:10'

	SET @MaLP = NULL
	-- Xác định loại phiếu mua hàng tương ứng
	SELECT @MaLP = MaLP
	FROM LOAIPHIEUMUAHANG WITH (NOLOCK)
	WHERE MaPH = @MaPH and TriGia > 0

	-- Tặng phiếu mua hàng
	IF @MaLP IS NOT NULL
	BEGIN
		INSERT INTO PHIEUMUAHANG (MaKH, NgayTang, MaLP, MaNV, HanSuDung, TrangThai)
		VALUES (@MaKH, GETDATE(), @MaLP, @MaNV, EOMONTH(GETDATE()), N'Chưa sử dụng')
	END

	-- Xem phân hạng khách hàng (Minh họa)
	SELECT *
	FROM KHACHHANG WITH (ROWLOCK)
	WHERE MaKH = @MaKH
COMMIT TRANSACTION

-- 2. Thực hiện cập nhật phân hạng khách hàng cho khách hàng MaKH = 1
BEGIN TRANSACTION
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	DECLARE @MaPH INT,
			@MaKH INT = 1,
			@MaNV INT = 1

	-- Tìm phân hạng
	EXEC usp_TimPhanHang @MaKH, @MaPH OUTPUT

	-- Cập nhật phân hạng
	UPDATE KHACHHANG
	SET MaPH = @MaPH, MaNV = @MaNV
	WHERE MaKH = @MaKH
COMMIT TRANSACTION

-- Xem phân hạng khách hàng sau khi cập nhật (Minh họa)
SELECT *
FROM KHACHHANG 
WHERE MaKH = @MaKH

-- TÌNH HUỐNG 2: Một nhân viên đang thực hiện cập nhật phân hạng khách hàng
-- thì khách hàng thực hiện đặt đơn hàng
-- 1. Phân hạng
BEGIN TRANSACTION
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
	DECLARE @MaPH INT,
			@MaKH INT = 1,
			@MaNV INT = 1

	-- Tìm phân hạng
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

	WAITFOR DELAY '00:00:10'

	--  Xác định phân hạng
	SELECT @MaPH = MaPH
	FROM PHANHANG WITH (NOLOCK)
	WHERE @TongTien >= TongMin 
	AND (@TongTien < TongMax OR TongMax is NULL)

	-- Cập nhật phân hạng
	UPDATE KHACHHANG
	SET MaPH = @MaPH, MaNV = @MaNV
	WHERE MaKH = @MaKH
COMMIT TRANSACTION

-- 2. Đặt đơn hàng
EXEC sp_TaoDonHang 
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



