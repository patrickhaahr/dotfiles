return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "catppuccin"
      require("catppuccin").setup({
        transparent_background = true,
      })
    end,
  },
  {
    "stevearc/conform.nvim",
    opts = require "configs.conform",
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },
  
  -- Mason auto-install
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "rust-analyzer",
        "codelldb",
        "lua-language-server",
        "css-lsp",
        "html-lsp",
      },
    },
  },

  {
    "mrcjkb/rustaceanvim",
    version = "^5",
    lazy = false,
    ft = "rust",
    config = function()
      local mason_path = vim.fn.stdpath "data" .. "/mason"
      local extension_path = mason_path .. "/packages/codelldb/extension/"
      local codelldb_path = extension_path .. "adapter/codelldb"
      local liblldb_path = extension_path .. "lldb/lib/liblldb.so"
      local cfg = require "rustaceanvim.config"

      vim.g.rustaceanvim = {
        server = {
          cmd = { vim.fn.stdpath("data") .. "/mason/bin/rust-analyzer" },
        },
        dap = {
          adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
        },
      }
    end,
  },
  {
    "rust-lang/rust.vim",
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end,
  },
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<leader>db",
        function() require("dap").toggle_breakpoint() end,
        desc = "debug toggle breakpoint",
        mode = "n",
      },
      {
        "<leader>dc",
        function() require("dap").continue() end,
        desc = "debug continue",
        mode = "n",
      },
      {
        "<leader>dl",
        function() require("dap").step_into() end,
        desc = "debug step into",
        mode = "n",
      },
      {
        "<leader>dj",
        function() require("dap").step_over() end,
        desc = "debug step over",
        mode = "n",
      },
      {
        "<leader>dk",
        function() require("dap").step_out() end,
        desc = "debug step out",
        mode = "n",
      },
      {
        "<leader>de",
        function() require("dap").terminate() end,
        desc = "debug terminate",
        mode = "n",
      },
      {
        "<leader>dr",
        function() require("dap").run_last() end,
        desc = "debug run last",
        mode = "n",
      },
    },
    config = function()
      local ok, dap = pcall(require, "dap")
      if not ok then return end

      -- Use adapter configured by rustaceanvim if available
      local ra = vim.g.rustaceanvim
      if ra and ra.dap and ra.dap.adapter then
        dap.adapters.codelldb = ra.dap.adapter
      end

      -- Provide a simple default rust configuration if none exists
      if not dap.configurations.rust or vim.tbl_isempty(dap.configurations.rust) then
        dap.configurations.rust = {
          {
            name = "Debug executable (codelldb)",
            type = "codelldb",
            request = "launch",
            program = function()
              local cwd = vim.fn.getcwd()
              local target_dir = cwd .. "/target/debug/"
              local dir_name = vim.fn.fnamemodify(cwd, ":t")
              local guess = target_dir .. dir_name

              -- If the guessed path isn't executable, try to pick the first executable in target/debug
              if vim.fn.executable(guess) ~= 1 then
                local files = vim.fn.glob(target_dir .. "*", 0, 1)
                for _, path in ipairs(files) do
                  if vim.fn.getftype(path) == "file" and vim.fn.executable(path) == 1 then
                    guess = path
                    break
                  end
                end
              end

              return vim.fn.input("Path to executable: ", guess, "file")
            end,
            cwd = "${workspaceFolder}",
            stopOnEntry = false,
            args = {},
            console = "integratedTerminal",
          },
        }
      end
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    keys = {
      {
        "<leader>du",
        function() require("dapui").toggle() end,
        desc = "debug ui toggle",
        mode = "n",
      },
    },
    config = function()
      local dapui = require("dapui")
      dapui.setup()
      local dap = require("dap")
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
  },
  {
    'saecki/crates.nvim',
    tag = 'stable',
    config = function()
        require('crates').setup()
    end,
  }
}
