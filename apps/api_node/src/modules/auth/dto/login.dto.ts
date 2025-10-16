import { IsEmail, IsIn, IsNotEmpty, IsString } from 'class-validator';

const ROLES = ['recruiter', 'candidate', 'admin'] as const;

type LoginRole = (typeof ROLES)[number];

export class LoginDto {
  @IsEmail()
  email!: string;

  @IsString()
  @IsNotEmpty()
  password!: string;

  @IsIn(ROLES)
  role!: LoginRole;
}
