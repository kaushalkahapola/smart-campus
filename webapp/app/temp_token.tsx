'use server';

import { asgardeo } from "@asgardeo/nextjs/server";

export async function getSessionData() {
  const client = await asgardeo();
  const sessionId = await client.getSessionId();
  const accessToken = await client.getAccessToken(sessionId as string);
  
  return {
    sessionId: sessionId || null,
    accessToken: accessToken || null
  };
}
