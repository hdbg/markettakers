###############################################################################
# 1. Prompt-stage fields (4 inputs)
###############################################################################
resource "authentik_stage_prompt_field" "username" {
  name      = "enroll-username"
  field_key = "username"
  label     = "Choose a username"
  type      = "username"
  required  = true
  order = 0
}

resource "authentik_stage_prompt_field" "email" {
  name      = "enroll-email"
  field_key = "email"
  label     = "Your e-mail address"
  type      = "email"
  required  = true
  order = 1
}

resource "authentik_stage_prompt_field" "password" {
  name      = "enroll-password"
  field_key = "password"
  label     = "Create a password"
  type      = "password"
  required  = true
  order = 2
}

resource "authentik_stage_prompt_field" "password_confirm" {
  name      = "enroll-password-confirm"
  field_key = "password_confirm"
  label     = "Confirm password"
  type      = "password"
  required  = true
  order = 3
}

###############################################################################
# 2. Single Prompt stage containing all four fields
###############################################################################
resource "authentik_stage_prompt" "signup_prompt" {
  name   = "signup-all-fields"
  fields = [
    authentik_stage_prompt_field.username.id,
    authentik_stage_prompt_field.email.id,
    authentik_stage_prompt_field.password.id,
    authentik_stage_prompt_field.password_confirm.id,
  ]
}

###############################################################################
# 3. User-write stage (creates the account)
###############################################################################
resource "authentik_stage_user_write" "create_user" {
  name                     = "create-user"
  create_users_as_inactive = false
  user_type = "internal"
  user_creation_mode = "always_create"

  create_users_group = authentik_group.steam_employee.id

}

###############################################################################
# 4. Enrollment flow (slug = default-enrollment)
###############################################################################
resource "authentik_flow" "default_enrollment" {
  name        = "Single-page onboarding"
  title       = "Register"
  slug        = "default-enrollment"
  designation = "enrollment"
  layout      = "stacked"

}

// acept invite stage
resource "authentik_stage_invitation" "accept_invite" {
  name = "invitation"
}
###############################################################################
# 5. Bind stages to the flow in order
###############################################################################
resource "authentik_flow_stage_binding" "accept_invite" {
  target = authentik_flow.default_enrollment.uuid
  stage  = authentik_stage_invitation.accept_invite.id
  order  = 0
}  

###############################################################################
# 5. Bind stages to the flow
###############################################################################
resource "authentik_flow_stage_binding" "bind_prompt" {
  target = authentik_flow.default_enrollment.uuid
  stage  = authentik_stage_prompt.signup_prompt.id
  order  = 1
}

resource "authentik_flow_stage_binding" "bind_user_write" {
  target = authentik_flow.default_enrollment.uuid
  stage  = authentik_stage_user_write.create_user.id
  order  = 2
}

###############################################################################
# 6. Policy that blocks authenticated users
###############################################################################
resource "authentik_policy_expression" "deny_authenticated" {
  name       = "deny-if-authenticated"
  expression = <<-PY
    # Fail the policy (and thus the flow) if the requester is already logged in
    return not request.user.is_authenticated
  PY
}

resource "authentik_policy_binding" "bind_policy_to_flow" {
  target = authentik_flow.default_enrollment.uuid
  policy = authentik_policy_expression.deny_authenticated.id
  order  = 0 # policies run before stages when bound to the flow
}