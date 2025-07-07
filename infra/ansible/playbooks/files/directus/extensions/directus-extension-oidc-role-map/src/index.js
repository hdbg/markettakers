import { createError } from '@directus/errors';

const NoRoleError = createError('FORBIDDEN', "You don't have any roles", 403);

async function fireHook(payload, userInfo, services, schemaFunctor) {
  const RolesService = new services.RolesService({
    schema: await schemaFunctor(),
  });

  for (const key of Object.keys(userInfo).filter((key) => key.startsWith("groups."))) {
	const providerGroupName = userInfo[key];
	if (providerGroupName != undefined) {
      const role = await RolesService.readByQuery(
        {
          filter: { name: { _eq: providerGroupName } },
        },
        {}
      );

      console.log(role);
      const roleId = role[0]?.id;
      console.log(roleId);

      if (roleId != null) {
        const ret = { ...payload, role: roleId };

        console.log("Returning role mapping:", ret);
        return ret;
      }
    }
  }

  throw new NoRoleError();

}

export default ({ filter }, { services, getSchema }) => {
  filter("auth.update", async (payload, { providerPayload }, context) => {
    return await fireHook(
      payload,
      providerPayload.userInfo,
      services,
      getSchema
    );
  });

  filter("auth.create", async (payload, meta, context) => {
    console.log("firing create: ", [payload, meta, context]);
    console.log("Provider payload: ", meta.providerPayload.userInfo);
    return await fireHook(
      payload,
      meta.providerPayload.userInfo,
      services,
      getSchema
    );
  });
};
