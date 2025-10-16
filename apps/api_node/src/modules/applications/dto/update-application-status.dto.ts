import { IsIn, IsNotEmpty, IsString } from 'class-validator';

const STATUSES = ['pending', 'screened', 'interview', 'offer', 'rejected'] as const;

type ApplicationStatus = (typeof STATUSES)[number];

export class UpdateApplicationStatusDto {
  @IsString()
  @IsNotEmpty()
  @IsIn(STATUSES)
  status!: ApplicationStatus;
}
