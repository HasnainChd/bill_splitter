// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    });
  }

  try {
    // 1. Get JWT from Authorization header
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No authorization header provided" }),
        {
          status: 401,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const token = authHeader.replace(/^Bearer\s+/i, "").trim();

    // 2. Create admin client using service role key
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!serviceRoleKey) {
      console.error("[delete-user] SUPABASE_SERVICE_ROLE_KEY environment variable is NOT set in Supabase Secrets!");
      return new Response(
        JSON.stringify({ error: "SUPABASE_SERVICE_ROLE_KEY is not configured in Supabase secrets." }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    // 3. Verify user token using admin client
    const {
      data: { user },
      error: userError,
    } = await supabaseAdmin.auth.getUser(token);

    if (userError || !user) {
      console.error("[delete-user] User verification failed:", userError);
      return new Response(
        JSON.stringify({ error: `Unauthorized: ${userError?.message || 'Invalid user token'}` }),
        {
          status: 401,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const userId = user.id;

    // 4a. Delete from public.users
    const { error: deletePublicError } = await supabaseAdmin
      .from("users")
      .delete()
      .eq("id", userId);

    if (deletePublicError) {
      console.error("[delete-user] Error deleting public.users record:", deletePublicError);
      return new Response(
        JSON.stringify({ error: `Failed to delete user profile data: ${deletePublicError.message}` }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    // 4b. Delete from auth.users (permanently removes authentication user)
    const { error: deleteAuthError } = await supabaseAdmin.auth.admin.deleteUser(
      userId
    );

    if (deleteAuthError) {
      console.error("[delete-user] Error deleting auth.users user:", deleteAuthError);
      return new Response(
        JSON.stringify({ error: `Failed to delete auth user credentials: ${deleteAuthError.message}` }),
        {
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: "Account deleted successfully",
      }),
      {
        status: 200,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  } catch (error: any) {
    console.error("[delete-user] Unexpected exception:", error);
    return new Response(
      JSON.stringify({ error: `Internal server error: ${error?.message || error}` }),
      {
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});
