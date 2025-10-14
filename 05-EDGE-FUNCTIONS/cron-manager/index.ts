// ═══════════════════════════════════════════════════════════════════
// EDGE FUNCTION : cron-manager
// ═══════════════════════════════════════════════════════════════════
// Remplace /api/v3/cron/* du backend Render
// Gestion CRUD des cron jobs pg_cron depuis le frontend
// ═══════════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  // ─────────────────────────────────────────────────────────────────
  // 1. Initialiser Supabase
  // ─────────────────────────────────────────────────────────────────
  const supabaseClient = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  )

  // ─────────────────────────────────────────────────────────────────
  // 2. Authentification Admin
  // ─────────────────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization')
  
  if (!authHeader) {
    return new Response(
      JSON.stringify({ error: 'Missing Authorization header' }), 
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    )
  }

  const token = authHeader.replace('Bearer ', '')
  const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
  
  if (authError || !user || user.app_metadata?.role !== 'admin') {
    return new Response(
      JSON.stringify({ error: 'Unauthorized - Admin role required' }), 
      { status: 403, headers: { 'Content-Type': 'application/json' } }
    )
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. Routing selon la méthode HTTP
  // ─────────────────────────────────────────────────────────────────
  const { method } = req
  const url = new URL(req.url)

  try {
    // ───────────────────────────────────────────────────────────────
    // GET : Liste des cron jobs
    // ───────────────────────────────────────────────────────────────
    if (method === 'GET') {
      console.log('📋 Fetching cron jobs list...')
      
      const { data: jobs, error } = await supabaseClient
        .rpc('get_cron_jobs_list')
      
      if (error) {
        throw new Error(`Failed to fetch jobs: ${error.message}`)
      }
      
      console.log(`✅ Found ${jobs?.length || 0} cron jobs`)
      
      return new Response(
        JSON.stringify(jobs || []), 
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // ───────────────────────────────────────────────────────────────
    // POST : Toggle ou créer cron job
    // ───────────────────────────────────────────────────────────────
    if (method === 'POST') {
      const body = await req.json()
      const { jobId, action } = body

      if (action === 'toggle' && jobId) {
        console.log(`🔄 Toggling job ${jobId}...`)
        
        const { data: result, error } = await supabaseClient
          .rpc('toggle_cron_job', { job_id: jobId })
        
        if (error) {
          throw new Error(`Toggle failed: ${error.message}`)
        }
        
        console.log('✅ Job toggled:', result)
        
        return new Response(
          JSON.stringify(result), 
          { headers: { 'Content-Type': 'application/json' } }
        )
      }

      // Créer un nouveau cron job (future feature)
      return new Response(
        JSON.stringify({ error: 'Create job not implemented yet' }), 
        { status: 501, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // ───────────────────────────────────────────────────────────────
    // DELETE : Supprimer un cron job
    // ───────────────────────────────────────────────────────────────
    if (method === 'DELETE') {
      const jobId = url.searchParams.get('id')
      
      if (!jobId) {
        return new Response(
          JSON.stringify({ error: 'Missing job ID' }), 
          { status: 400, headers: { 'Content-Type': 'application/json' } }
        )
      }
      
      console.log(`🗑️ Deleting job ${jobId}...`)
      
      const { data: result, error } = await supabaseClient
        .rpc('delete_cron_job', { job_id: parseInt(jobId) })
      
      if (error) {
        throw new Error(`Delete failed: ${error.message}`)
      }
      
      console.log('✅ Job deleted:', result)
      
      return new Response(
        JSON.stringify(result), 
        { headers: { 'Content-Type': 'application/json' } }
      )
    }

    // ───────────────────────────────────────────────────────────────
    // Méthode non supportée
    // ───────────────────────────────────────────────────────────────
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }), 
      { status: 405, headers: { 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('❌ Error in cron-manager:', error)
    
    return new Response(
      JSON.stringify({ 
        error: error.message,
        timestamp: new Date().toISOString()
      }), 
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }
})

