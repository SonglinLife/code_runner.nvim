local commands = require("code_runner.commands")
local o = require("code_runner.options")
local M = {}

M.setup = function(user_options)
  o.set(user_options or {})
  M.load_runners()
  vim.api.nvim_exec(
    [[
      function! RunKeyCompletion(lead, cmd, cursor)
        echo a:cmd
        echo a:cursor
        let l = len(a:lead) - 1
        if l >= 0
          let filtered_args = copy(g:crSupportedFileTypes)
          call filter(filtered_args, {_, v -> v[:l] ==# a:lead})
          if !empty(filtered_args)
            return filtered_args
          endif
        endif
        return g:crSupportedFileTypes
      endfunction

      function! RunnerCompletion(lead, cmd, cursor)
        let valid_args = ['float', 'tab', 'term', 'toggle', 'toggleterm']
        let l = len(a:lead) - 1
        if l >= 0
          let filtered_args = copy(valid_args)
          call filter(filtered_args, {_, v -> v[:l] ==# a:lead})
          if !empty(filtered_args)
            return filtered_args
          endif
        endif
        return valid_args
      endfunction

			command! CRProjects lua require('code_runner').open_project_manager()
      command! CRFiletype lua require('code_runner').open_filetype_suported()
			command! -nargs=? -complete=customlist,RunKeyCompletion RunCode lua require('code_runner').run_code("<args>")
      command! -nargs=? -complete=customlist,RunnerCompletion RunFile lua require('code_runner').run_filetype("<args>")
      command! -nargs=? -complete=customlist,RunnerCompletion RunProject lua require('code_runner').run_project("<args>")
			command! RunClose lua require('code_runner').run_close()
		]] ,
    false
  )
end

local function open_json(json_path)
  local command = "tabnew " .. json_path
  vim.cmd(command)
end

local function get_filetype_suported()
  local opt = o.get()
  local keyset={}
  local n=0
  for k,v in pairs(opt.filetype) do
    n=n+1
    keyset[n]=k
  end
  return keyset
end

M.load_runners = function()
  -- Load json config and convert to table
  local opt = o.get()
  local load_json_as_table = require("code_runner.load_json")

  -- convert json filetype as table lua
  if vim.tbl_isempty(opt.filetype) then
    opt.filetype = load_json_as_table(opt.filetype_path)
  end

  -- convert json project as table lua
  if vim.tbl_isempty(opt.project) then
    opt.project = load_json_as_table(opt.project_path)
  end

  -- Message if json file not exist
  if vim.tbl_isempty(opt.filetype) then
    vim.notify(
      "Not exist command for filetypes or format invalid, if use json please execute :CRFiletype or if use lua edit setup",
      vim.log.levels.ERROR,
      { title = "Code Runner Error" }
    )
  else
    vim.g.crSupportedFileTypes = get_filetype_suported()
  end
end

M.run_code = commands.run
M.run_filetype = commands.run_filetype
M.run_project = commands.run_project
M.run_close = commands.run_close
M.get_filetype_command = commands.get_filetype_command
M.get_project_command = commands.get_project_command

M.open_filetype_suported = function()
  open_json(o.get().filetype_path)
end

M.open_project_manager = function()
  open_json(o.get().project_path)
end

return M
