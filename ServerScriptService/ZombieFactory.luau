-- ZombieFactory: bouwt de placeholder-zombie (blokpop, armen vooruit, rode ogen).
-- Gedrag zit in ZombieAI; dit is puur het "kostuum" + Humanoid.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local ZombieFactory = {}

local SKIN = Color3.fromRGB(110, 160, 90)   -- zombie-groen
local SHIRT = Color3.fromRGB(60, 45, 90)    -- gescheurd Spaceland-parkuniform (paarsig)
local PANTS = Color3.fromRGB(40, 40, 50)

local function makePart(name, size, color, parent)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.Parent = parent
	return p
end

local function weldTo(root, part)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = root
end

function ZombieFactory.create()
	local model = Instance.new("Model")
	model.Name = "Zombie"

	-- HumanoidRootPart: het onzichtbare "karretje" waar de Humanoid mee stuurt
	local hrp = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), SHIRT, model)
	hrp.Transparency = 1
	hrp.CanCollide = true
	hrp.CFrame = CFrame.new(0, 3, 0)

	local torso = makePart("Torso", Vector3.new(2, 2, 1), SHIRT, model)
	torso.CFrame = hrp.CFrame

	local head = makePart("Head", Vector3.new(1.2, 1.2, 1.2), SKIN, model)
	head.CFrame = hrp.CFrame * CFrame.new(0, 1.6, 0)

	-- rode neon-oogjes aan de voorkant van het hoofd
	for _, dx in ipairs({ -0.3, 0.3 }) do
		local eye = makePart("Eye", Vector3.new(0.2, 0.2, 0.1), Color3.fromRGB(255, 40, 40), model)
		eye.Material = Enum.Material.Neon
		eye.CFrame = head.CFrame * CFrame.new(dx, 0.1, -0.6)
	end

	-- armen vooruit: klassieke zombie-houding (arm-lengte wijst naar voren)
	for _, dx in ipairs({ -1.5, 1.5 }) do
		local arm = makePart("Arm", Vector3.new(1, 2, 1), SKIN, model)
		arm.CFrame = hrp.CFrame * CFrame.new(dx, 0.5, -1) * CFrame.Angles(math.rad(-90), 0, 0)
	end

	-- benen (stijf, glijden over de grond — looppas komt in de polish-fase)
	for _, dx in ipairs({ -0.5, 0.5 }) do
		local leg = makePart("Leg", Vector3.new(1, 2, 1), PANTS, model)
		leg.CFrame = hrp.CFrame * CFrame.new(dx, -2, 0)
	end

	-- alles vastlassen aan het karretje
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= hrp then
			weldTo(hrp, p)
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = Config.Zombie.Health
	humanoid.Health = Config.Zombie.Health
	humanoid.WalkSpeed = Config.Zombie.WalkSpeed
	humanoid.HipHeight = 2          -- houdt het karretje op de juiste hoogte boven de grond
	humanoid.RequiresNeck = false   -- ons simpele lijf heeft geen officiële nek-verbinding
	humanoid.Parent = model

	model.PrimaryPart = hrp
	return model
end

return ZombieFactory
