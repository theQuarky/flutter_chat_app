enum Gender {
  male,
  female,
}

export default interface IUser {
  uid?: string;
  displayName?: string;
  dob?: string;
  gender?: Gender;
  image?: string;
  friends?: string[];
  deviceToken?: string;
}
