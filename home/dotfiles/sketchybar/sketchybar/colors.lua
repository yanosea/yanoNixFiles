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
  bg1 = 0xff374247,
  bg2 = 0xff374247,

  with_alpha = function(color, alpha)
    if alpha > 1.0 or alpha < 0.0 then
      return color
    end
    local bit = require("bit")
    return bit.bor(bit.band(color, 0x00ffffff), bit.lshift(math.floor(alpha * 255.0), 24))
  end,
}
