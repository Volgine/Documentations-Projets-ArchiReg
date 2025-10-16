# 🎨 ARCHITECTURE FRONTEND ARCHIREG

**Date** : 15 octobre 2025  
**Version** : 3.2  
**Framework** : Next.js 14 + React 18 + TypeScript  
**Host** : Vercel (Production)

---

## 🎯 RESPONSABILITÉS FRONTEND

### **CE QU'IL FAIT** ✅

```
1. Interface Chat utilisateur
   ↓ SSE Streaming + Markdown
2. Dashboard Admin complet
   ↓ 21 métriques + 4 onglets
3. Contrôle Micro-service Légifrance
   ↓ START/STOP/MODE MASSIVE/MAINTENANCE
4. Tests système (27 tests)
   ↓ 9 Backend + 18 Edge Functions
5. Auth Supabase
   ↓ JWT + RLS + Admin role
```

**Fonctions clés** :
1. **Chat** : Interface streaming SSE + Markdown renderer
2. **Admin** : Dashboard métriques + contrôles
3. **Tests** : Interface tests système hybrides
4. **Auth** : Supabase Auth + gestion session
5. **Realtime** : Supabase Realtime channels

### **CE QU'IL NE FAIT PAS** ❌

- ❌ Génération LLM (Backend Groq)
- ❌ RAG Search (Backend pgvector)
- ❌ Collecte données (Micro-service)
- ❌ Parsing documents (Workers)

---

## 📊 PAGES PRINCIPALES

### **1. Chat (/chat)** 💬

**Fichier** : `app/chat/page.tsx`

**Fonctionnalités** :
- ✅ Interface conversation streaming
- ✅ Markdown renderer (React-Markdown)
- ✅ Code highlighting (Prism.js)
- ✅ Historique conversations
- ✅ Citations sources RAG
- ✅ Loading states élégants

**Composants** :
```typescript
// Chat principal
<ChatContainer>
  <ConversationList />      // Sidebar historique
  <MessageStream />          // Messages + streaming
  <InputBox />               // Prompt utilisateur
</ChatContainer>
```

**Streaming SSE** :
```typescript
const streamResponse = async (message: string) => {
  const eventSource = new EventSource(
    `/api/chat/streaming?message=${encodeURIComponent(message)}`
  );
  
  eventSource.onmessage = (event) => {
    const chunk = JSON.parse(event.data);
    setMessages(prev => appendChunk(prev, chunk));
  };
  
  eventSource.onerror = () => {
    eventSource.close();
  };
};
```

---

### **2. Admin Dashboard (/admin)** 📊

**Fichier** : `ArchiReg-Front/pages/admin.tsx`

**Architecture** : 4 onglets spécialisés

#### **Onglet 1 : Vue d'ensemble** 🌐

```typescript
<OverviewTab>
  <PipelineStatus />        // État collecte
  <QueueMetrics />          // files_queue stats
  <PerformanceKPIs />       // Métriques temps réel
  <HealthMonitoring />      // Santé système
</OverviewTab>
```

**Métriques affichées** :
- Pipeline status (running/stopped)
- Files queue (total, pending, processed)
- Workers actifs
- Performance temps réel

---

#### **Onglet 2 : Workers** 👷

```typescript
<WorkersTab>
  <WorkersTable />          // Tableau détaillé workers
  <WorkersKPIs />           // KPI temps réel
</WorkersTab>
```

**Données affichées** :
| Worker | Status | Processed | Speed | Errors |
|--------|--------|-----------|-------|--------|
| Worker-1 | ✅ Active | 104,231 | 12.5/s | 0.02% |
| Worker-2 | ✅ Active | 103,987 | 12.3/s | 0.01% |
| Worker-3 | ✅ Active | 103,782 | 12.1/s | 0.03% |

---

#### **Onglet 3 : Performance & Temps** ⏱️

```typescript
<PerformanceTab>
  <Timeline24h />           // Graphique activité 24h
  <Historical30d />         // Évolution 30 jours
  <TopHours />              // Heures de pointe
  <RecentBatches />         // Derniers batches
</PerformanceTab>
```

**Graphiques** :
- Timeline 24h : Fichiers traités par heure
- Historique 30j : Évolution documents
- Top heures : Activité par heure de la journée
- Recent batches : 10 derniers batches

---

#### **Onglet 4 : Qualité & Debug** 🐛

```typescript
<QualityTab>
  <ErrorsList />            // Erreurs récentes
  <HeavyFiles />            // Fichiers lourds
  <SizeDistribution />      // Distribution taille
  <Duplicates />            // Doublons détectés
</QualityTab>
```

**Métriques qualité** :
- Taux erreurs parsing
- Fichiers > 10 MB
- Distribution taille documents
- Doublons (même content_hash)

---

### **Données Admin** 📈

**Source** : Edge Function `admin-stats`

```typescript
interface AdminMetrics {
  // Pipeline
  pipeline_status: "running" | "stopped";
  mode: "MASSIVE" | "MAINTENANCE";
  
  // Queue
  total_files_queue: number;
  pending_files: number;
  processed_files: number;
  
  // Documents
  total_documents: number;
  documents_with_embeddings: number;
  avg_processing_time_seconds: number;
  
  // Performance
  processing_rate_per_hour: number;
  success_rate_percent: number;
  error_rate_percent: number;
  
  // Workers
  active_workers: number;
  worker_1_processed: number;
  worker_2_processed: number;
  worker_3_processed: number;
  
  // Qualité
  duplicate_files_count: number;
  heavy_files_count: number;
  recent_errors: string[];
  
  // Timestamps
  last_updated: string;
}
```

**Récupération** :
```typescript
const fetchAdminMetrics = async () => {
  const response = await fetch(
    `${SUPABASE_URL}/functions/v1/admin-stats?action=get`,
    {
      headers: {
        "Authorization": `Bearer ${serviceRoleKey}`
      }
    }
  );
  
  const data: AdminMetrics = await response.json();
  return data;
};
```

---

### **3. Tests Système (/tests)** 🧪

**Fichier** : `app/tests/page.tsx`

**Architecture** :
```typescript
<SystemTestsPage>
  <TestsGrid>
    <BackendTestsSection>     // 9 tests Backend
      {BACKEND_TESTS.map(test => <TestCard />)}
    </BackendTestsSection>
    
    <EdgeTestsSection>        // 18 tests Edge
      {EDGE_TESTS.map(test => <TestCard />)}
    </EdgeTestsSection>
  </TestsGrid>
  
  <TestResults />             // Résultats temps réel
</SystemTestsPage>
```

**Exécution tests** :
```typescript
const runTest = async (testName: string, type: "backend" | "edge") => {
  const url = type === "backend"
    ? `/api/v3/system-tests/${testName}`
    : `${SUPABASE_URL}/functions/v1/system-tests?test=${testName}`;
  
  const start = Date.now();
  
  try {
    const response = await fetch(url);
    const result = await response.json();
    
    return {
      success: result.success,
      latency: Date.now() - start,
      data: result
    };
  } catch (error) {
    return {
      success: false,
      error: error.message
    };
  }
};
```

---

## 🔧 COMPOSANTS RÉUTILISABLES

### **1. MarkdownRenderer** 📝

**Fichier** : `components/chat/MarkdownRenderer.tsx`

```typescript
import ReactMarkdown from 'react-markdown';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';

export function MarkdownRenderer({ content }: { content: string }) {
  return (
    <ReactMarkdown
      components={{
        code({ node, inline, className, children, ...props }) {
          const match = /language-(\w+)/.exec(className || '');
          return !inline && match ? (
            <SyntaxHighlighter
              language={match[1]}
              style={vscDarkPlus}
              {...props}
            >
              {String(children).replace(/\n$/, '')}
            </SyntaxHighlighter>
          ) : (
            <code className={className} {...props}>
              {children}
            </code>
          );
        }
      }}
    >
      {content}
    </ReactMarkdown>
  );
}
```

---

### **2. LoadingSpinner** ⏳

**Fichier** : `components/ui/LoadingSpinner.tsx`

```typescript
export function LoadingSpinner({ size = "md" }: { size?: "sm" | "md" | "lg" }) {
  return (
    <div className="flex items-center justify-center">
      <div className={`animate-spin rounded-full border-4 border-blue-500 border-t-transparent ${SIZE_CLASSES[size]}`} />
    </div>
  );
}
```

---

### **3. MetricCard** 📊

**Fichier** : `components/admin/MetricCard.tsx`

```typescript
export function MetricCard({ 
  title, 
  value, 
  icon, 
  trend 
}: MetricCardProps) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm text-gray-600">{title}</p>
          <p className="text-3xl font-bold mt-2">{value}</p>
        </div>
        <div className="text-4xl">{icon}</div>
      </div>
      {trend && (
        <div className={`mt-4 text-sm ${trend > 0 ? 'text-green-600' : 'text-red-600'}`}>
          {trend > 0 ? '↑' : '↓'} {Math.abs(trend)}%
        </div>
      )}
    </div>
  );
}
```

---

## 🔐 AUTHENTIFICATION

### **Supabase Auth**

**Fichier** : `lib/supabaseClient.ts`

```typescript
import { createClient } from '@supabase/supabase-js';

export const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
);

// Helper auth
export const getCurrentUser = async () => {
  const { data: { session } } = await supabase.auth.getSession();
  return session?.user;
};

// Helper admin check
export const isAdmin = async () => {
  const user = await getCurrentUser();
  return user?.app_metadata?.role === 'admin';
};
```

---

## 📊 STATE MANAGEMENT

### **Zustand Stores**

**Fichier** : `src/stores/chatStore.ts`

```typescript
import { create } from 'zustand';

interface ChatState {
  messages: Message[];
  conversations: Conversation[];
  isStreaming: boolean;
  addMessage: (message: Message) => void;
  setStreaming: (streaming: boolean) => void;
}

export const useChatStore = create<ChatState>((set) => ({
  messages: [],
  conversations: [],
  isStreaming: false,
  addMessage: (message) => set((state) => ({
    messages: [...state.messages, message]
  })),
  setStreaming: (streaming) => set({ isStreaming: streaming })
}));
```

---

## 🎨 DESIGN SYSTEM

### **Tailwind Configuration**

**Fichier** : `tailwind.config.js`

```javascript
module.exports = {
  content: [
    './pages/**/*.{js,ts,jsx,tsx}',
    './components/**/*.{js,ts,jsx,tsx}',
    './app/**/*.{js,ts,jsx,tsx}'
  ],
  theme: {
    extend: {
      colors: {
        primary: '#3B82F6',
        secondary: '#10B981',
        accent: '#F59E0B'
      }
    }
  }
};
```

---

## 🚀 DÉPLOIEMENT VERCEL

### **Configuration**

**Fichier** : `vercel.json`

```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "rewrites": [
    {
      "source": "/api/:path*",
      "destination": "https://agent-orchestrateur-backend.onrender.com/api/:path*"
    }
  ]
}
```

**Variables d'environnement** :
```bash
NEXT_PUBLIC_SUPABASE_URL=https://joozqsjbcwrqyeqepnev.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
NEXT_PUBLIC_API_URL=/api  # Rewrite vers Backend
```

---

## 🎉 Résumé Architecture

**Frontend moderne et performant** :
- ✅ Next.js 14 + React 18
- ✅ TypeScript strict
- ✅ Chat streaming SSE
- ✅ Dashboard admin (4 onglets, 21 métriques)
- ✅ Tests système (27 tests)
- ✅ Markdown + code highlighting
- ✅ Supabase Auth
- ✅ Tailwind CSS
- ✅ Déployé Vercel

**Interface utilisateur au top !** 🎨

