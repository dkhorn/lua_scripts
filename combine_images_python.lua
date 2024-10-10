--[[

    combine_images_python.lua - call a python script to combine this image with its neighbors
]]

local dt = require "darktable"
local du = require "lib/dtutils"
local df = require "lib/dtutils.file"
local dtsys = require "lib/dtutils.system"
local gettext = dt.gettext.gettext
local gimp_widget = nil

du.check_min_api_version("7.0.0", "gimp") 

dt.gettext.bindtextdomain("gimp", dt.configuration.config_dir .."/lua/locale/")

local function _(msgid)
    return gettext(msgid)
end

-- return data structure for script_manager

local script_data = {}

script_data.metadata = {
  name = "combine_images_py",
  purpose = _("Call a python script to combine this image with its neighbors"),
  author = "Daniel Horn <dkhorn@gmail.com>",
  help = "https://docs.darktable.org/lua/stable/lua.scripts.manual/scripts/contrib/gimp"
}

script_data.destroy = nil -- function to destory the script
script_data.destroy_method = nil -- set to hide for libs since we can't destroy them commpletely yet, otherwise leave as nil
script_data.restart = nil -- how to restart the (lib) script after it's been hidden - i.e. make it visible again
script_data.show = nil -- only required for libs since the destroy_method only hides them


local function show_status(storage, image, format, filename,
  number, total, high_quality, extra_data)
    dt.print(string.format(_("export image %i/%i"), number, total))
end

local function gimp_edit(storage, image_table, extra_data) --finalize

  local python_executable = df.check_if_bin_exists("python")
  if not python_executable then
    dt.print_error("Python not found")
    return
  end
  
  -- list of exported images
  local img_list

   -- reset and create image list
  img_list = ""

  for image,exported_image in pairs(image_table) do
    local startCommand =   python_executable .. " c:\\bin\\combine_images.py " .. image .. " 10 --hdr --mean --median --verbose"
    dt.print_log(startCommand);
    dtsys.external_command(startCommand)
  end

  -- if not run_detached then

  --   -- for each of the image, exported image pairs
  --   --   move the exported image into the directory with the original
  --   --   then import the image into the database which will group it with the original
  --   --   and then copy over any tags other than darktable tags

  --   for image,exported_image in pairs(image_table) do

  --     local myimage_name = image.path .. "/" .. df.get_filename(exported_image)

  --     while df.check_if_file_exists(myimage_name) do
  --       myimage_name = df.filename_increment(myimage_name)
  --       -- limit to 99 more exports of the original export
  --       if string.match(df.get_basename(myimage_name), "_(d-)$") == "99" then
  --         break
  --       end
  --     end

  --     dt.print_log("moving " .. exported_image .. " to " .. myimage_name)
  --     local result = df.file_move(exported_image, myimage_name)

  --     if result then
  --       dt.print_log("importing file")
  --       local myimage = dt.database.import(myimage_name)

  --       group_if_not_member(image, myimage)

  --       for _,tag in pairs(dt.tags.get_tags(image)) do
  --         if not (string.sub(tag.name,1,9) == "darktable") then
  --           dt.print_log("attaching tag")
  --           dt.tags.attach(tag,myimage)
  --         end
  --       end
  --     end
  --   end
  -- end
end

local function destroy()
  dt.destroy_storage("module_combine_images_py")
end

-- Register

gimp_widget = dt.new_widget("check_button"){
  label = _("run detached"),
  tooltip = _("don't import resulting image back into darktable"),
  value = dt.preferences.read("combine_images_py", "run_detached", "bool"),
  clicked_callback = function(this)
    dt.preferences.write("combine_images_py", "run_detached", "bool", this.value)
  end
}

dt.register_storage("module_combine_images_py", _("Combine Images"), show_status, gimp_edit, nil, nil, gimp_widget)

--
script_data.destroy = destroy

return script_data
