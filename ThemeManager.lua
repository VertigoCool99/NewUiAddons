local HttpService = game:GetService('HttpService')

local ThemeManager = {} do
	ThemeManager.Folder = 'Float_Balls/Ui/Themes/'
	ThemeManager.Library = nil
	ThemeManager.BuiltInThemes = {

	}

	function ThemeManager:ApplyTheme(theme)
		local customThemeData = self:GetCustomTheme(theme)
		local data = customThemeData or self.BuiltInThemes[theme]
		if not data then return end
		local scheme = data[2]
		for idx, col in next, customThemeData or scheme do
			self.Library.Colors[idx] = Color3.fromHex(col)
			
			if Options[idx] then
				Options[idx]:SetValueRGB(Color3.fromHex(col))
			end
		end

		self:ThemeUpdate()
	end

	function ThemeManager:ThemeUpdate()
		-- This allows us to force apply themes without loading the themes tab :)
		local options = { "Background", "Active", "ItemBorder", "ItemBackground", "Text" , "DisabledText", "Risky"}
		for i, field in next, options do
			if Options and Options[field] then
				self.Library[field] = Options[field].Value
			end
		end
		self.Library.Functions:UpdateColors()
	end

	function ThemeManager:LoadDefault()		
		local theme = 'Default'
		local content = isfile(self.Folder..'default.theme') and readfile(self.Folder..'default.theme')

		local isDefault = true
		if content then
			if self.BuiltInThemes[content] then
				theme = content
			elseif self:GetCustomTheme(content) then
				theme = content
				isDefault = false;
			end
		elseif self.BuiltInThemes[self.DefaultTheme] then
		 	theme = self.DefaultTheme
		end

		if isDefault then
			Options.ThemeManager_ThemeList:SetValue(theme)
		else
			self:ApplyTheme(theme)
		end
	end

	function ThemeManager:SaveDefault(theme)
		writefile(self.Folder..'default.txt', theme)
	end

	function ThemeManager:CreateThemeManager(groupbox)
		groupbox:AddColorPicker('BackgroundColor', {Text = "Background Color"; Default = self.Library.Colors.Background });
		groupbox:AddColorPicker('AccentColor', {Text = "Accent Color"; Default = self.Library.Colors.Active });
        groupbox:AddColorPicker('ItemBorderColor', {Text = "Outline Color"; Default = self.Library.Colors.ItemBorder });
        groupbox:AddColorPicker('ItemBackground', {Text = "Item Background Color";Default = self.Library.Colros.ItemBackground });
		groupbox:AddColorPicker('TextColor', {Text = "Text Color";Default = self.Library.Colors.Text });
        groupbox:AddColorPicker('DisabledTextColor', {Text = "Disabled Text Color";Default = self.Library.Colors.DisabledText });
        groupbox:AddColorPicker('RiskyTextColor', {Text = "Risky Text Color";Default = self.Library.Colors.Risky });

		local ThemesArray = {}
		for Name, Theme in next, self.BuiltInThemes do
			table.insert(ThemesArray, Name)
		end

		table.sort(ThemesArray, function(a, b) return self.BuiltInThemes[a][1] < self.BuiltInThemes[b][1] end)

		groupbox:AddDivider()
		groupbox:AddDropdown('ThemeManager_ThemeList', { Text = 'Themes', Values = ThemesArray, Default = 1 })

		groupbox:AddButton('Set As Default', function()
			self:SaveDefault(Options.ThemeManager_ThemeList.Value)
			self.Library:Notify({Title="Theme";Text=string.format('Set Default Theme To %q', Options.ThemeManager_ThemeList.Value);Duration=3})
		end)

		Options.ThemeManager_ThemeList:OnChanged(function()
			self:ApplyTheme(Options.ThemeManager_ThemeList.Value)
		end)

		groupbox:AddDivider()
		groupbox:AddInput('ThemeManager_CustomThemeName', { Text = 'Custom Theme Name' })
		groupbox:AddDropdown('ThemeManager_CustomThemeList', { Text = 'Custom Themes', Values = self:ReloadCustomThemes(), AllowNull = true, Default = 1 })
		groupbox:AddDivider()
		
		groupbox:AddButton({Text='Save Theme', Func=function() 
			self:SaveCustomTheme(Options.ThemeManager_CustomThemeName.Value)

			Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end})
        groupbox:AddButton({Text='Load Theme', Func=function() 
            self:ApplyTheme(Options.ThemeManager_CustomThemeList.Value) 
		end})

        groupbox:AddButton({Text='Refresh List', Func=function() 
            Options.ThemeManager_CustomThemeList:SetValues(self:ReloadCustomThemes())
			Options.ThemeManager_CustomThemeList:SetValue(nil)
		end})

        groupbox:AddButton({Text='Set As Default', Func=function() 
			if Options.ThemeManager_CustomThemeList.Value ~= nil and Options.ThemeManager_CustomThemeList.Value ~= '' then
				self:SaveDefault(Options.ThemeManager_CustomThemeList.Value)
				self.Library:Notify(string.format('Set default theme to %q', Options.ThemeManager_CustomThemeList.Value))
			end
		end})

		ThemeManager:LoadDefault()

		local function UpdateTheme()
			self:ThemeUpdate()
		end

		Options.BackgroundColor:OnChanged(UpdateTheme)
		Options.AccentColor:OnChanged(UpdateTheme)
		Options.ItemBorderColor:OnChanged(UpdateTheme)
		Options.ItemBackground:OnChanged(UpdateTheme)
		Options.TextColor:OnChanged(UpdateTheme)
        Options.DisabledTextColor:OnChanged(UpdateTheme)
        Options.RiskyTextColor:OnChanged(UpdateTheme)
	end

	function ThemeManager:GetCustomTheme(file)
		local path = self.Folder .. '/themes/' .. file
		if not isfile(path) then
			return nil
		end

		local data = readfile(path)
		local success, decoded = pcall(HttpService.JSONDecode, HttpService, data)
		
		if not success then
			return nil
		end

		return decoded
	end

	function ThemeManager:SaveCustomTheme(file)
		if file:gsub(' ', '') == '' then
			return self.Library:Notify({Title="ERROR",Text='File Name Cannot Be nil',Duration=3})
		end

		local theme = {}
		local fields = { "Background", "Active", "ItemBorder", "ItemBackground", "Text" , "DisabledText", "Risky"}

		for _, field in next, fields do
			theme[field] = Options[field].Value:ToHex()
		end

		writefile(self.Folder..file..'.theme', HttpService:JSONEncode(theme))
	end

	function ThemeManager:ReloadCustomThemes()
		local list = listfiles(self.Folder)

		local out = {}
		for i = 1, #list do
			local file = list[i]
			if file:sub(-6) == '.theme' then

				local pos = file:find('.theme', 1, true)
				local char = file:sub(pos, pos)

				while char ~= '/' and char ~= '\\' and char ~= '' do
					pos = pos - 1
					char = file:sub(pos, pos)
				end

				if char == '/' or char == '\\' then
					table.insert(out, file:sub(pos + 1))
				end
			end
		end

		return out
	end

	function ThemeManager:SetLibrary(lib)
		self.Library = lib
	end

	function ThemeManager:SetFolder(folder)
		self.Folder = folder
	end

	function ThemeManager:CreateGroupBox(tab)
		assert(self.Library, 'Must Set ThemeManager.Library First!')
		return tab:AddLeftGroupbox('Themes')
	end

	function ThemeManager:ApplyToTab(tab)
		assert(self.Library, 'Must Set ThemeManager.Library First!')
		local groupbox = self:CreateGroupBox(tab)
		self:CreateThemeManager(groupbox)
	end

	function ThemeManager:ApplyToGroupbox(groupbox)
		assert(self.Library, 'Must Set ThemeManager.Library First!')
		self:CreateThemeManager(groupbox)
	end
end

return ThemeManager
