ALTER TABLE `complexes`
  ADD COLUMN IF NOT EXISTS `name` VARCHAR(191) NULL,
  ADD COLUMN IF NOT EXISTS `address` VARCHAR(191) NULL;

UPDATE `complexes`
SET
  `name` = COALESCE(`name`, `alias`),
  `address` = COALESCE(`address`, `roadAddress`);
