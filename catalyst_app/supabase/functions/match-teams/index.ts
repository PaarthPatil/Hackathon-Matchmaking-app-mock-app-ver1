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

    const { userId, hackathonId } = await req.json()

    // 1. Fetch user skills
    const { data: profile } = await supabaseClient
      .from('profiles')
      .select('skills')
      .eq('id', userId)
      .single()

    const userSkills = (profile?.skills as string[]) || []

    // 2. Fetch teams for hackathon
    const { data: teams } = await supabaseClient
      .from('teams')
      .select('*')
      .eq('hackathon_id', hackathonId)

    if (!teams) return new Response(JSON.stringify([]), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })

    // 3. Simple matching logic (Fuzzy/Weighted Skill Match)
    const recommendations = teams.map((team) => {
      const requiredSkills = (team.required_skills as string[]) || []
      const matchedSkills = userSkills.filter(s => requiredSkills.includes(s))
      
      const score = requiredSkills.length > 0 
        ? matchedSkills.length / requiredSkills.length 
        : 0.5; // Neutral score if no skills required

      return {
        ...team,
        matchingScore: score,
        matchingExplanation: matchedSkills.length > 0 
          ? `You match ${matchedSkills.length} required skill(s): ${matchedSkills.join(', ')}.`
          : 'You bring unique cross-functional value to this team.'
      }
    })

    // Sort by score descending
    recommendations.sort((a, b) => b.matchingScore - a.matchingScore)

    return new Response(JSON.stringify(recommendations), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 400,
    })
  }
})
