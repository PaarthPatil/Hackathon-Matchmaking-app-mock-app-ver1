import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
    )

    const { userId, teamId } = await req.json()

    // 1. Fetch team details to get creator_id and name
    const { data: team, error: teamError } = await supabaseClient
      .from('teams')
      .select('creator_id, name')
      .eq('id', teamId)
      .single()

    if (teamError || !team) throw new Error('Team not found')

    // 2. Insert into team_members with pending status
    const { error: joinError } = await supabaseClient
      .from('team_members')
      .insert({
        team_id: teamId,
        user_id: userId,
        status: 'pending',
        role: 'Pending Member'
      })

    if (joinError) throw joinError

    // 3. Create Notification for creator
    const { error: notifError } = await supabaseClient
      .from('notifications')
      .insert({
        user_id: team.creator_id,
        type: 'team_join_request',
        message: `A user is interested in joining your team: ${team.name}`,
        reference_id: teamId
      })

    if (notifError) console.error('Notification failed to send but join went through', notifError)

    return new Response(JSON.stringify({ success: true, message: 'Join request sent!' }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
