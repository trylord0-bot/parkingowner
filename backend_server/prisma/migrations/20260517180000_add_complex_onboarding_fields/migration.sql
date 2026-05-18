ALTER TABLE `users`
  ADD COLUMN `currentComplexId` VARCHAR(191) NULL;

ALTER TABLE `complexes`
  ADD COLUMN `roadAddress` VARCHAR(191) NULL,
  ADD COLUMN `jibunAddress` VARCHAR(191) NULL,
  ADD COLUMN `zipCode` VARCHAR(191) NULL,
  ADD COLUMN `alias` VARCHAR(191) NULL;

UPDATE `complexes`
SET
  `roadAddress` = `address`,
  `alias` = `name`
WHERE `roadAddress` IS NULL OR `alias` IS NULL;

UPDATE `users` u
JOIN (
  SELECT `userId`, MIN(`complexId`) AS `complexId`
  FROM `complex_members`
  WHERE `isActive` = 1
  GROUP BY `userId`
) cm ON cm.`userId` = u.`id`
SET u.`currentComplexId` = cm.`complexId`
WHERE u.`currentComplexId` IS NULL;

ALTER TABLE `complexes`
  MODIFY COLUMN `roadAddress` VARCHAR(191) NOT NULL,
  MODIFY COLUMN `alias` VARCHAR(191) NOT NULL;

CREATE UNIQUE INDEX `complexes_roadAddress_key` ON `complexes`(`roadAddress`);
CREATE INDEX `users_currentComplexId_idx` ON `users`(`currentComplexId`);

ALTER TABLE `users`
  ADD CONSTRAINT `users_currentComplexId_fkey`
  FOREIGN KEY (`currentComplexId`) REFERENCES `complexes`(`id`)
  ON DELETE SET NULL ON UPDATE CASCADE;
