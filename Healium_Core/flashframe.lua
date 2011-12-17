-----------------------------------------------------
-- Flash Frame

-- APIs:
--FlashFrame:ShowFlashFrame(frame, color, size, brightness): start a flash on frame, size must be 10 times bigger than frame size to see it, brightness: 1->100
--FlashFrame:HideFlashFrame(frame): stop a flash
--FlashFrame:Blink(frame, duration): start a blink
--FlashFrame:StopBlink(frame): stop a blink
--FlashFrame:Pulse(frame, scale): start a pulse
--FlashFrame:StopPulse(frame): stop a pulse
--FlashFrame:ZoomIn(frame, scale): zoom in
--FlashFrame:ZoomOut(frame): zoom out


local H, C, L = unpack(select(2, ...))

-- Namespace
H.FlashFrame = {}
local FlashFrame = H.FlashFrame

-- Create flash frame on a frame
local function CreateFlashFrame(frame)
	if frame.ffFlashFrame then return end

	frame.ffFlashFrame = CreateFrame("Frame", nil, frame)
	frame.ffFlashFrame:Hide()
	frame.ffFlashFrame:SetAllPoints(frame)
	frame.ffFlashFrame.texture = frame.ffFlashFrame:CreateTexture(nil, "OVERLAY")
	frame.ffFlashFrame.texture:SetTexture("Interface\\Cooldown\\star4")
	frame.ffFlashFrame.texture:SetPoint("CENTER", frame.ffFlashFrame, "CENTER")
	frame.ffFlashFrame.texture:SetBlendMode("ADD")
	frame.ffFlashFrame:SetAlpha(1)
	frame.ffFlashFrame.updateInterval = 0.02
	frame.ffFlashFrame.lastFlashTime = 0
	frame.ffFlashFrame.timeSinceLastUpdate = 0
	frame.ffFlashFrame:SetScript("OnUpdate", function (self, elapsed)
		if not self:IsShown() then return end
		self.timeSinceLastUpdate = self.timeSinceLastUpdate + elapsed
		if self.timeSinceLastUpdate >= self.updateInterval then
			local oldModifier = self.flashModifier
			self.flashModifier = oldModifier - oldModifier * self.timeSinceLastUpdate
			self.timeSinceLastUpdate = 0
			self.alpha = self.flashModifier * self.flashBrightness
			if oldModifier < 0.1 or self.alpha <= 0 then
				self:Hide()
			else
				self.texture:SetHeight(oldModifier * self:GetHeight() * self.flashSize)
				self.texture:SetWidth(oldModifier * self:GetWidth() * self.flashSize)
				self.texture:SetAlpha(self.alpha)
			end
		end
	end)
end

-- Show flash frame
function FlashFrame:ShowFlashFrame(frame, color, size, brightness, blink)
	if not frame.ffFlashFrame then
		-- Create flash frame on-the-fly
		CreateFlashFrame(frame)
	end
	
	if blink and frame:GetName() and not UIFrameIsFading(frame) then
		UIFrameFlash(frame, 0, 0.2, 0.2, true, 0, 0)
	end

	-- Dont flash too often
	local now = GetTime()
	if now - frame.ffFlashFrame.lastFlashTime < 1 then return end
	frame.ffFlashFrame.lastFlashTime = now

	-- Show flash frame
	frame.ffFlashFrame.flashModifier = 1
	frame.ffFlashFrame.flashSize = (size or 240) / 100
	frame.ffFlashFrame.flashBrightness = (brightness or 100) / 100
	frame.ffFlashFrame.texture:SetAlpha(1 * frame.ffFlashFrame.flashBrightness)
	frame.ffFlashFrame.texture:SetHeight(frame.ffFlashFrame:GetHeight() * frame.ffFlashFrame.flashSize)
	frame.ffFlashFrame.texture:SetWidth(frame.ffFlashFrame:GetWidth() * frame.ffFlashFrame.flashSize)
	if type(color) == "table" then
		frame.ffFlashFrame.texture:SetVertexColor(color.r or 1, color.g or 1, color.b or 1)
	elseif type(color) == "string" then
		local color = COLORTABLE[color:lower()]
		if color then
			frame.ffFlashFrame.texture:SetVertexColor(color.r or 1, color.g or 1, color.b or 1)
		else
			frame.ffFlashFrame.texture:SetVertexColor(1, 1, 1)
		end
	else
		frame.ffFlashFrame.texture:SetVertexColor(1, 1, 1)
	end
	frame.ffFlashFrame:Show()
end

-- Hide flash frame
function FlashFrame:HideFlashFrame(frame)
	if not frame.ffFlashFrame then return end

	frame.ffFlashFrame.flashModifier = 0
	frame.ffFlashFrame:Hide()
end

--------------------------------------------
-- Blink Animation: http://wowprogramming.com/docs/widgets_hierarchy
function FlashFrame:Blink(self, duration)
	if not self.ffBlink then
		self.ffBlink = self:CreateAnimationGroup("Blink")

		local fadeIn = self.ffBlink:CreateAnimation("ALPHA", "FadeIn")
		fadeIn:SetChange(1)
		fadeIn:SetOrder(2)
		self.ffBlink.fadeIn = fadeIn

		local fadeOut = self.ffBlink:CreateAnimation("ALPHA", "FadeOut")
		fadeOut:SetChange(-1)
		fadeOut:SetOrder(1)
		self.ffBlink.fadeOut = fadeOut
	end

	self.ffBlink.fadeIn:SetDuration(duration)
	self.ffBlink.fadeOut:SetDuration(duration)
	self.ffBlink:Play()
end

function FlashFrame:StopBlink(self)
	if self.ffBlink then
		self.ffBlink:Stop()
	end
end

--------------------------------------------
-- Pulse Animation: http://wowprogramming.com/docs/widgets_hierarchy
function FlashFrame:Pulse(self, scale)
	scale = scale or 1.5
	if not self.ffPulse then
		self.ffPulse = self:CreateAnimationGroup("Pulse")

		local pulseIn = self.ffPulse:CreateAnimation("Scale")
		pulseIn:SetScale(scale, scale)
		pulseIn:SetDuration(0.2)
		pulseIn:SetOrder(1)
		self.ffPulse.pulseIn = pulseIn

		local pulseOut = self.ffPulse:CreateAnimation("Scale")
		pulseOut:SetScale(0.5, 0.5)
		pulseOut:SetDuration(0.8)
		pulseOut:SetOrder(2)
		self.ffPulse.pulseOut = pulseOut
	end

	self.ffPulse:Play()
end

function FlashFrame:StopPulse(self)
	if self.ffPulse then
		self.ffPulse:Stop()
	end
end

--------------------------------------------
-- Zoom Animation: http://wowprogramming.com/docs/widgets_hierarchy
function FlashFrame:ZoomIn(self, scale)
	scale = scale or 1.5
	if not self.ffZoom then
		self.ffZoom = self:CreateAnimationGroup("Zoom")

		local zoomIn = self.ffZoom:CreateAnimation("Scale")
		zoomIn:SetScale(scale, scale)
		zoomIn:SetDuration(0.2)
		zoomIn:SetOrder(1)
		self.ffZoom.zoomIn = zoomIn

		local keepZoom = self.ffZoom:CreateAnimation("Scale")
		keepZoom:SetScale(scale, scale)
		keepZoom:SetDuration(60)
		keepZoom:SetOrder(2)
		self.ffZoom.keepZoom = keepZoom
	end
	self.ffZoom:Play()
end

function FlashFrame:ZoomOut(self)
	if self.ffZoom then
		self.ffZoom:Stop()
	end
end