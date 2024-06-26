pub type InputWithValidation {
  InputWithValidation(value: String, errors: List(String))
}

pub type RegistrationForm {
  RegistrationForm(
    email: InputWithValidation,
    name: String,
    password: InputWithValidation,
    password_confirm: InputWithValidation,
  )
}

pub fn default_registration_form() {
  RegistrationForm(
    email: InputWithValidation("", []),
    name: "",
    password: InputWithValidation("", []),
    password_confirm: InputWithValidation("", []),
  )
}
