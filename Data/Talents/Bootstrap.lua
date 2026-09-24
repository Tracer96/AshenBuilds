-- Shared talent-data registry for Ashen Builds and the embedded Talented dataset.
-- The generated class files write into TalentedTooltipData, so both names must
-- reference the same table before those files load.
TalentedTooltipData = TalentedTooltipData or AshenBuildsTalentData or {}
AshenBuildsTalentData = TalentedTooltipData

TalentedDataOverride = TalentedDataOverride or {spelldata={},tabdata={}}
Talented = Talented or {}

function Talented:SetClassData(class, data)
  TalentedTooltipData[class] = data
  AshenBuildsTalentData[class] = data
end
