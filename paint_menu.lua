-- paint menu 
-- type !paint in chat to open it

if SERVER then

	util.AddNetworkString("PaintMenu_Open")

	hook.Add("PlayerSay", "paintmenuhook", function(ply, text)

		local txt = string.lower(string.Trim(text))

		if txt == "!paint" then
			net.Start("PaintMenu_Open")
			net.Send(ply)
			return ""
		end

	end)

	return

end

-- all the client stuff 

local paintOn = false
local paintColor = Color(255, 0, 0, 200)   -- red by default
local paintSize = 10                        -- smallest 
local nextTime = 0
local paintDelay = 0.3    -- time between each circle
local myCircles = {}
local maxCircles = 50     -- max 50 circles 
local paintFrame


local function GetPerpendicularVectors(normal)
	local up = Vector(0, 0, 1)

	-- if the surface is a floor or ceiling we need a different reference
	if math.abs(normal:Dot(up)) > 0.99 then
		up = Vector(0, 1, 0)
	end

	local right = normal:Cross(up)
	right:Normalize()

	local fwd = right:Cross(normal)
	fwd:Normalize()

	return right, fwd
end


local function BuildCircleMesh(pos, normal, radius, col)
	local right, fwd = GetPerpendicularVectors(normal)

	local segments = 32
	local offset = pos + normal * 0.3

	local mat = CreateMaterial("paintcircle_" .. math.random(1, 999999), "UnlitGeneric", {
		["$basetexture"] = "vgui/white",
		["$vertexcolor"] = "1",
		["$vertexalpha"] = "1",
		["$translucent"] = "1",
		["$nocull"] = "1"   
	})

	local m = Mesh()

	mesh.Begin(m, MATERIAL_TRIANGLES, segments)

	for i = 0, segments - 1 do
		local a1 = math.rad(i / segments * 360)
		local a2 = math.rad((i + 1) / segments * 360)

		local p1 = offset
			+ right * math.cos(a1) * radius
			+ fwd   * math.sin(a1) * radius

		local p2 = offset
			+ right * math.cos(a2) * radius
			+ fwd   * math.sin(a2) * radius

		mesh.Color(col.r, col.g, col.b, col.a)
		mesh.Position(offset)
		mesh.AdvanceVertex()

		mesh.Color(col.r, col.g, col.b, col.a)
		mesh.Position(p1)
		mesh.AdvanceVertex()

		mesh.Color(col.r, col.g, col.b, col.a)
		mesh.Position(p2)
		mesh.AdvanceVertex()
	end

	mesh.End()

	return m, mat
end


hook.Add("Think", "paintmenu_think", function()
	if not paintOn then return end
	if CurTime() < nextTime then return end

	local tr = LocalPlayer():GetEyeTrace()

	if tr.Hit then
		local col = Color(paintColor.r, paintColor.g, paintColor.b, 200)
		local m, mat = BuildCircleMesh(tr.HitPos, tr.HitNormal, paintSize, col)

		table.insert(myCircles, {
			mesh = m,
			mat = mat
		})

		-- remove oldest one if we hit the limit
		if #myCircles > maxCircles then
			myCircles[1].mesh = nil
			table.remove(myCircles, 1)
		end

		nextTime = CurTime() + paintDelay
	end
end)


hook.Add("PostDrawTranslucentRenderables", "paintmenu_render", function()
	for _, c in ipairs(myCircles) do
		render.SetMaterial(c.mat)
		c.mesh:Draw()
	end
end)

-- menu

local function MakePaintMenu()

	if IsValid(paintFrame) then
		paintFrame:Remove()
	end

	local fw = 220
	local fh = 225

	paintFrame = vgui.Create("DFrame")
	paintFrame:SetSize(fw, fh)
	paintFrame:SetTitle("")
	paintFrame:ShowCloseButton(false)
	paintFrame:MakePopup()
	paintFrame:SetDraggable(false)

	local xpos = 20
	local ypos = ScrH() / 2 - fh / 2
	paintFrame:SetPos(xpos, ypos)

	paintFrame.Paint = function(s, w, h)
		draw.RoundedBox(6, 0, 0, w, h, Color(35, 35, 35, 240))
		draw.RoundedBox(6, 0, 0, w, 24, Color(25, 25, 25, 255))
		draw.SimpleText("Paint Menu", "DermaDefaultBold", 10, 6, color_white)
	end

	local closeBtn = vgui.Create("DButton", paintFrame)
	closeBtn:SetSize(20, 20)
	closeBtn:SetPos(fw - 22, 2)
	closeBtn:SetText("X")
	closeBtn.DoClick = function()
		paintFrame:Remove()
	end

	-- gotta declare these first or it crashes when OnChange tries to use them
	local cbActivate
	local cbRed
	local cbGreen
	local cbBlue
	local cb10
	local cb25
	local cb50size


	cbActivate = vgui.Create("DCheckBoxLabel", paintFrame)
	cbActivate:SetPos(10, 35)
	cbActivate:SetText("Activate Paint")
	cbActivate:SetValue(paintOn)
	cbActivate.OnChange = function(s, v)
		paintOn = v
	end

	cbRed = vgui.Create("DCheckBoxLabel", paintFrame)
	cbRed:SetPos(10, 60)
	cbRed:SetText("Red")
	cbRed:SetValue(paintColor.r == 255 and paintColor.g == 0)
	cbRed.OnChange = function(s, v)
		if v == true then
			paintColor = Color(255, 0, 0, 200)
			cbGreen:SetValue(false)
			cbBlue:SetValue(false)
		end
	end

	cbGreen = vgui.Create("DCheckBoxLabel", paintFrame)
	cbGreen:SetPos(10, 80)
	cbGreen:SetText("Green")
	cbGreen:SetValue(paintColor.g == 255 and paintColor.r == 0)
	cbGreen.OnChange = function(s, v)
		if v == true then
			paintColor = Color(0, 255, 0, 200)
			cbRed:SetValue(false)
			cbBlue:SetValue(false)
		end
	end

	cbBlue = vgui.Create("DCheckBoxLabel", paintFrame)
	cbBlue:SetPos(10, 100)
	cbBlue:SetText("Blue")
	cbBlue:SetValue(paintColor.b == 255 and paintColor.r == 0)
	cbBlue.OnChange = function(s, v)
		if v == true then
			paintColor = Color(0, 0, 255, 200)
			cbRed:SetValue(false)
			cbGreen:SetValue(false)
		end
	end

	cb10 = vgui.Create("DCheckBoxLabel", paintFrame)
	cb10:SetPos(10, 130)
	cb10:SetText("10")
	cb10:SetValue(paintSize == 10)
	cb10.OnChange = function(s, v)
		if v == true then
			paintSize = 10
			cb25:SetValue(false)
			cb50size:SetValue(false)
		end
	end

	cb25 = vgui.Create("DCheckBoxLabel", paintFrame)
	cb25:SetPos(10, 150)
	cb25:SetText("25")
	cb25:SetValue(paintSize == 25)
	cb25.OnChange = function(s, v)
		if v == true then
			paintSize = 25
			cb10:SetValue(false)
			cb50size:SetValue(false)
		end
	end

	cb50size = vgui.Create("DCheckBoxLabel", paintFrame)
	cb50size:SetPos(10, 170)
	cb50size:SetText("50")
	cb50size:SetValue(paintSize == 50)
	cb50size.OnChange = function(s, v)
		if v == true then
			paintSize = 50
			cb10:SetValue(false)
			cb25:SetValue(false)
		end
	end

	local clearBtn = vgui.Create("DButton", paintFrame)
	clearBtn:SetSize(fw - 20, 22)
	clearBtn:SetPos(10, 198)
	clearBtn:SetText("Clear Paint")
	clearBtn.DoClick = function()
		myCircles = {}
	end

end


-- backup in case net message doesnt fire for some reason
hook.Add("OnPlayerChat", "paintmenu_chatbackup", function(ply, text)
	if ply ~= LocalPlayer() then return end

	local txt = string.lower(string.Trim(text))

	if txt == "!paint" then
		MakePaintMenu()
		return true
	end
end)

net.Receive("PaintMenu_Open", function()
	MakePaintMenu()
end)