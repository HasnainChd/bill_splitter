// @ts-nocheck
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.7.1";
// @ts-ignore: Deno LSP cannot resolve subpath types for firebase-admin
import { initializeApp, cert } from "npm:firebase-admin@12/app";
// @ts-ignore: Deno LSP cannot resolve subpath types for firebase-admin
import { getMessaging } from "npm:firebase-admin@12/messaging";

// Initialize Firebase Admin SDK using service account credentials from Environment variables
const firebaseProjectId = Deno.env.get("FIREBASE_PROJECT_ID");
const firebaseClientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL");
const firebasePrivateKey = Deno.env.get("FIREBASE_PRIVATE_KEY")?.replace(/\\n/g, "\n");

let messaging: any = null;
if (firebaseProjectId && firebaseClientEmail && firebasePrivateKey) {
  try {
    const app = initializeApp({
      credential: cert({
        projectId: firebaseProjectId,
        clientEmail: firebaseClientEmail,
        privateKey: firebasePrivateKey,
      }),
    });
    messaging = getMessaging(app);
  } catch (e) {
    console.error("Failed to initialize Firebase Admin SDK:", e);
  }
}

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

serve(async (req) => {
  try {
    const { table, operation, new_record, old_record } = await req.json();

    const record = new_record || old_record;
    if (!record) {
      return new Response("No record found in payload", { status: 400 });
    }

    if (table === "broadcast") {
      if (messaging) {
        await messaging.send({
          topic: 'equally_all_users',
          notification: {
            title: record.title,
            body: record.body,
          },
          android: {
            notification: {
              channelId: 'equally_notifications',
              priority: 'high',
            }
          }
        });
        return new Response(JSON.stringify({ success: true, message: "Broadcast sent" }), {
          headers: { "Content-Type": "application/json" },
          status: 200,
        });
      } else {
        console.log("Firebase Messaging not initialized (credentials missing). Broadcast payload:", record);
        return new Response("Firebase Messaging not initialized", { status: 500 });
      }
    }

    const groupId = record.group_id;
    if (!groupId) {
      return new Response("No group_id found in record", { status: 400 });
    }

    // 1. Fetch Group Details
    const { data: group, error: groupErr } = await supabase
      .from("groups")
      .select("name, currency")
      .eq("id", groupId)
      .single();

    if (groupErr || !group) {
      console.error("Error fetching group:", groupErr);
      return new Response(`Group not found: ${groupErr?.message}`, { status: 400 });
    }

    // 2. Determine initiator and title/body of notification
    let initiatorId = "";
    let title = record.title || `Group Update`;
    let body = record.body || `A change has occurred in ${group.name}.`;

    if (table === "expenses") {
      initiatorId = record.paid_by;
      const expenseTitle = record.title || record.description || "Expense";
      const expenseAmount = Number(record.amount || 0).toFixed(0);
      const currency = group.currency || "PKR";

      if (operation === "INSERT") {
        const isSettlement = expenseTitle === 'Settle Payment' || expenseTitle === 'Payment';
        if (isSettlement) {
          title = "✅ Payment Received";
          body = `{initiator} marked ${currency} ${expenseAmount} as paid in ${group.name}`;
        } else {
          title = `New Expense in ${group.name}`;
          body = `{initiator} added ${expenseTitle} · ${currency} ${expenseAmount} total`;
        }
      } else if (operation === "UPDATE") {
        title = `Expense Updated in ${group.name}`;
        body = `{initiator} updated ${expenseTitle} in ${group.name}`;
      } else if (operation === "DELETE") {
        title = `Expense Deleted in ${group.name}`;
        body = `{initiator} deleted ${expenseTitle} in ${group.name}`;
      }
    } else if (table === "group_notifications") {
      initiatorId = record.user_id;
      title = `${group.name}`;
      if (record.event_type === "removed") {
        body = `{initiator} was removed from ${group.name}`;
      } else if (record.event_type === "joined") {
        body = `{initiator} joined ${group.name}`;
      } else {
        body = `{initiator} has left ${group.name}`;
      }
    } else if (table === "group_members") {
      // added_by = person who did the adding (actor)
      // user_id = person being added (recipient)
      // If added_by exists use it, otherwise fall back 
      // to user_id (when someone joins via invite themselves)
      initiatorId = record.added_by || record.user_id;

      if (operation === "INSERT") {
        // Skip notification if this is the creator's own row
        if (record.is_creator === true) {
          return new Response(
            JSON.stringify({ skipped: true, reason: 'creator_insert' }), 
            { status: 200 }
          );
        }

        // If person added themselves (via invite code) or added_by is missing:
        const addedThemselves = !record.added_by || record.added_by === record.user_id;
        title = `New Member in ${group.name}`;
        body = addedThemselves
          ? `{initiator} joined ${group.name}`
          : `{initiator} added you to ${group.name}`;
      } else if (operation === "DELETE") {
        initiatorId = record.user_id; // person who left or was removed
        title = `${group.name}`;

        // Fetch recent event_type from group_notifications table for this user & group
        const { data: latestNotif } = await supabase
          .from("group_notifications")
          .select("event_type")
          .eq("group_id", groupId)
          .eq("user_id", record.user_id)
          .order("created_at", { ascending: false })
          .limit(1)
          .maybeSingle();

        const isRemoved = latestNotif?.event_type === "removed";
        body = isRemoved
          ? `{initiator} was removed from ${group.name}`
          : `{initiator} has left the group`;
      }
    } else if (table === "requests") {
      initiatorId = record.user_id;
      const currency = record.currency || group.currency || "PKR";
      if (record.amount) {
        const amountStr = Number(record.amount).toFixed(0);
        title = `💰 Request from {initiator}`;
        const noteStr = record.note ? ` ("${record.note}")` : "";
        body = `{initiator} requested ${currency} ${amountStr} from you in ${group.name}${noteStr}`;
      } else {
        title = `Payment Request in ${group.name}`;
        body = `{initiator} requested to settle up in ${group.name}`;
      }
    } else if (table === "payment_reminders") {
      initiatorId = record.sender_id;
      const amount = Number(record.amount || 0).toFixed(0);
      const currency = record.currency || group.currency || "PKR";
      title = `💰 Reminder from {initiator}`;
      body = `You owe ${currency} ${amount} in ${group.name}. Tap to settle up.`;
    } else if (table === "settlements") {
      initiatorId = record.sender_id;
      const amount = Number(record.amount || 0).toFixed(0);
      const currency = record.currency || group.currency || "PKR";
      title = "✅ Payment Received";
      body = `{initiator} marked ${currency} ${amount} as paid in ${group.name}`;
    }

    // 3. Resolve Initiator Full Name
    let initiatorName = "Someone";
    if (initiatorId) {
      const { data: profile, error: profErr } = await supabase
        .from("users")
        .select("fullName, full_name")
        .eq("id", initiatorId)
        .single();
      
      if (!profErr && profile) {
        initiatorName = profile.fullName || profile.full_name || "Someone";
      }
    }
    title = title.replace("{initiator}", initiatorName);
    body = body.replace("{initiator}", initiatorName);

    // 4. Find FCM Tokens for all other members of the group
    const { data: members, error: memErr } = await supabase
      .from("group_members")
      .select("user_id")
      .eq("group_id", groupId);

    if (memErr || !members) {
      console.error("Error fetching group members:", memErr);
      return new Response("Error fetching members", { status: 500 });
    }

    let memberIds = [];
    if (record.target_user_ids && Array.isArray(record.target_user_ids)) {
      memberIds = record.target_user_ids;
    } else if (record.target_user_id) {
      memberIds = [record.target_user_id];
    } else {
      memberIds = members.map((m) => m.user_id);
    }

    if (initiatorId) {
      memberIds = memberIds.filter((id) => id !== initiatorId);
    }

    if (memberIds.length === 0) {
      return new Response("No target members to notify", { status: 200 });
    }

    // Fetch tokens for these user IDs
    const { data: tokensData, error: tokErr } = await supabase
      .from("user_tokens")
      .select("fcm_token")
      .in("user_id", memberIds);

    if (tokErr || !tokensData) {
      console.error("Error fetching FCM tokens:", tokErr);
      return new Response("Error fetching user tokens", { status: 500 });
    }

    const tokens = tokensData.map((t) => t.fcm_token).filter(Boolean);
    if (tokens.length === 0) {
      return new Response("No registered FCM tokens found", { status: 200 });
    }

    console.log(`Sending notifications to ${tokens.length} devices...`);

    // 5. Send FCM Notifications
    if (messaging) {
      const sendPromises = tokens.map((token) =>
        messaging.send({
          token,
          notification: {
            title,
            body,
          },
          data: {
            groupId,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
        }).catch((err: any) => {
          console.error(`Failed to send to token ${token}:`, err);
        })
      );
      await Promise.all(sendPromises);
    } else {
      console.log("Firebase Messaging not initialized (credentials missing). Notification payload:", { title, body });
    }

    return new Response(JSON.stringify({ success: true, notifiedCount: tokens.length }), {
      headers: { "Content-Type": "application/json" },
      status: 200,
    });
  } catch (error) {
    console.error("Error processing function:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { "Content-Type": "application/json" },
      status: 500,
    });
  }
});
