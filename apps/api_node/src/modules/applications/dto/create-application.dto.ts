import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateApplicationDto {
  @IsString()
  @IsNotEmpty()
  offerId!: string;

  @IsString()
  @IsNotEmpty()
  candidateId!: string;

  @IsString()
  @IsOptional()
  coverLetter?: string;
}
