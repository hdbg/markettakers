import jwt_decode from "jwt-decode";
import { OauthException } from "./exceptions";

const openIdRoleFilter = async(
      rolesService, 
      isUpdate: boolean, 
      { accessToken, userPayload, provider }, 
      env
) => {
  // get role name from token
  const token = jwt_decode(accessToken);
  const prefix = `AUTH_${provider.toUpperCase()}`
  const claimName = env[`${prefix}_CLAIM_NAME`] || 'directus_role';
  const role = token[claimName];

  if (!role) {
    throw new OauthException('User does not have a role assigned', 403,  'AUTH_ROLES_MISSING')
  }

  // find role id by name
  const roles = await rolesService.readByQuery({
    filter: {name: { _eq: role }},
  });

  if (!roles || roles.length < 1) {
    throw new OauthException('The user role do not match any CMS roles', 403,  'AUTH_ROLE_NOT_FOUND')
  }

  // build user overrides
  let overwriteUserInfo = env[`${prefix}_OVERWRITE_USER_INFO`];
  if(isUpdate && overwriteUserInfo === 'create') {
    overwriteUserInfo = false;
  }
  
  return { 
    ...(overwriteUserInfo ? userPayload : null), 
    role: roles[0].id
  };
}

export default ({ filter }, { services: { RolesService }, env }) => {
  const handler = (isUpdate) => (
    async (payload, meta, { schema, database }) => {
      const rolesService = await new RolesService({ schema, knex: database});
      return await openIdRoleFilter(rolesService, isUpdate, meta, env);
    }
  )

  filter('auth.openid.create', handler(false));
  filter('auth.openid.update', handler(true));
};