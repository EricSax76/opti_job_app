import {
  IsArray,
  IsBoolean,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString
} from 'class-validator';

const SENIORITY = ['junior', 'mid', 'senior'] as const;

type Seniority = (typeof SENIORITY)[number];

export class CreateOfferDto {
  @IsString()
  @IsNotEmpty()
  companyId!: string;

  @IsString()
  @IsNotEmpty()
  title!: string;

  @IsString()
  @IsNotEmpty()
  description!: string;

  @IsArray()
  @IsString({ each: true })
  skills!: string[];

  @IsIn(SENIORITY)
  seniority!: Seniority;

  @IsString()
  @IsNotEmpty()
  location!: string;

  @IsBoolean()
  remote = false;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  languages?: string[];
}
