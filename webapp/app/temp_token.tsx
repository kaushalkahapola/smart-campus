'use server';

import { asgardeo } from "@asgardeo/nextjs/server";

export async function getSessionData() {
  const client = await asgardeo();
  const sessionId = await client.getSessionId();
  
  // Only try to get the access token if we have a session ID
  let accessToken = null;
  if (sessionId) {
    try {
      accessToken = await client.getAccessToken(sessionId as string);
    } catch (error) {
      console.error('Error getting access token:', error);
      // Continue without access token
    }
  }
  
  return {
    sessionId: sessionId || null,
    accessToken: accessToken || null
  };
}
