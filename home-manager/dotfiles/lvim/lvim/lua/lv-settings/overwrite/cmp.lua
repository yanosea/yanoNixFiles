-- cmp
-- enabled cmp-cmdline
lvim.builtin.cmp.cmdline.enable = true
-- disable <C-J>, <C-k> mapping in insert mode for cmp to avoid conflict with skkeleton
lvim.builtin.cmp.mapping["<C-J>"].i = nil
lvim.builtin.cmp.mapping["<C-J>"].c = nil
lvim.builtin.cmp.mapping["<C-K>"].i = nil
lvim.builtin.cmp.mapping["<C-K>"].c = nil
