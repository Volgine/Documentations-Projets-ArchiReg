// ═══════════════════════════════════════════════════════════════════
// EDGE FUNCTION : admin-stats
// ═══════════════════════════════════════════════════════════════════
// Remplace /api/v3/admin/database-stats du backend Render
// Latence : <100ms (au lieu de 30-40s)
// Région : eu-west-3 (Europe - France)
// ═══════════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  // ─────────────────────────────────────────────────────────────────
  // 1. Initialiser le client Supabase
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
      {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }

  const token = authHeader.replace('Bearer ', '')
  
  const { data: { user }, error: authError } = await supabaseClient.auth.getUser(token)
  
  if (authError || !user) {
    console.error('Auth error:', authError)
    return new Response(
      JSON.stringify({ error: 'Unauthorized', details: authError?.message }), 
      {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }

  // Vérifier que l'user est admin (app_metadata.role = 'admin')
  const isAdmin = user.app_metadata?.role === 'admin'
  
  if (!isAdmin) {
    return new Response(
      JSON.stringify({ error: 'Forbidden - Admin role required' }), 
      {
        status: 403,
        headers: { 'Content-Type': 'application/json' }
      }
    )
  }

  // ─────────────────────────────────────────────────────────────────
  // 3. Déterminer l'action (get ou refresh)
  // ─────────────────────────────────────────────────────────────────
  const url = new URL(req.url)
  const action = url.searchParams.get('action') || 'get'

  try {
    const startTime = Date.now()

    // ─────────────────────────────────────────────────────────────
    // 3.1 Action REFRESH : Rafraîchir la vue matérialisée
    // ─────────────────────────────────────────────────────────────
    if (action === 'refresh') {
      console.log('🔄 Refreshing admin metrics view...')
      
      const { data: refreshResult, error: refreshError } = await supabaseClient
        .rpc('refresh_admin_metrics_view')
      
      if (refreshError) {
        throw new Error(`Refresh failed: ${refreshError.message}`)
      }
      
      console.log('✅ View refreshed:', refreshResult)
    }

    // ─────────────────────────────────────────────────────────────
    // 3.2 Récupérer les métriques depuis la vue
    // ─────────────────────────────────────────────────────────────
    const { data, error } = await supabaseClient
      .from('admin_metrics_view')
      .select('*')
      .single()

    if (error) {
      console.error('Query error:', error)
      throw new Error(`Query failed: ${error.message}`)
    }

    const duration = Date.now() - startTime

    // ─────────────────────────────────────────────────────────────
    // 4. Retourner les métriques (format compatible frontend)
    // ─────────────────────────────────────────────────────────────
    return new Response(
      JSON.stringify({
        success: true,
        data: data,
        meta: {
          action: action,
          duration_ms: duration,
          timestamp: new Date().toISOString(),
          user_id: user.id,
          edge_function: 'admin-stats',
          region: 'eu-west-3'
        }
      }), 
      {
        headers: { 
          'Content-Type': 'application/json',
          'Cache-Control': 'max-age=60, stale-while-revalidate=300'
        }
      }
    )

  } catch (error) {
    console.error('❌ Error in admin-stats:', error)
    
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

