return {
	black = 0xff2d353b,
	white = 0xffd3c6aa,
	red = 0xffe67e80,
	green = 0xffa7c080,
	blue = 0xff7fbbb3,
	yellow = 0xffdbbc7f,
	orange = 0xffe69875,
	magenta = 0xffd699b6,
	grey = 0xff7a8478,
	transparent = 0x00000000,

	bar = {
		bg = 0xf02d353b,
		border = 0xff2d353b,
	},
	popup = {
		bg = 0xc02d353b,
		border = 0xff7a8478,
	},
	bg1 = 0xff343f44,
	bg2 = 0xff343f44,

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end

		-- ビットライブラリを使わずに同等の処理を行う
		local alpha_byte = math.floor(alpha * 255.0)
		local rgb_part = color % 0x1000000 -- 下位24ビットを取得（RGBの部分）
		local alpha_part = alpha_byte * 0x1000000 -- 上位8ビットにアルファ値を設定

		return rgb_part + alpha_part -- 両方を足し合わせる
	end,
}
