export interface ChatMessage {
  role: 'user' | 'assistant';
  content: string;
}

export interface Conversation {
  id: string;
  title: string;
  messages: ChatMessage[];
  createdAt: number;
  updatedAt: number;
}

const CONVERSATIONS_INDEX_KEY = 'conversations_index';

function getConvKey(id: string) {
  return `conv_${id}`;
}

export async function saveConversation(conv: Conversation): Promise<void> {
  try {
    await puter.kv.set(getConvKey(conv.id), JSON.stringify(conv));
    const index = await getConversationsIndex();
    const exists = index.find(c => c.id === conv.id);
    if (exists) {
      exists.title = conv.title;
      exists.updatedAt = conv.updatedAt;
    } else {
      index.push({ id: conv.id, title: conv.title, createdAt: conv.createdAt, updatedAt: conv.updatedAt });
    }
    await puter.kv.set(CONVERSATIONS_INDEX_KEY, JSON.stringify(index));
  } catch (_e) {
    // fallback to localStorage
    localStorage.setItem(getConvKey(conv.id), JSON.stringify(conv));
    const raw = localStorage.getItem(CONVERSATIONS_INDEX_KEY);
    const index: any[] = raw ? JSON.parse(raw) : [];
    const exists = index.find(c => c.id === conv.id);
    if (exists) {
      exists.title = conv.title;
      exists.updatedAt = conv.updatedAt;
    } else {
      index.push({ id: conv.id, title: conv.title, createdAt: conv.createdAt, updatedAt: conv.updatedAt });
    }
    localStorage.setItem(CONVERSATIONS_INDEX_KEY, JSON.stringify(index));
  }
}

export async function loadConversation(id: string): Promise<Conversation | null> {
  try {
    const raw = await puter.kv.get(getConvKey(id));
    return raw ? JSON.parse(raw) : null;
  } catch (_e) {
    const raw = localStorage.getItem(getConvKey(id));
    return raw ? JSON.parse(raw) : null;
  }
}

export async function getConversationsIndex(): Promise<Array<{ id: string; title: string; createdAt: number; updatedAt: number }>> {
  try {
    const raw = await puter.kv.get(CONVERSATIONS_INDEX_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch (_e) {
    const raw = localStorage.getItem(CONVERSATIONS_INDEX_KEY);
    return raw ? JSON.parse(raw) : [];
  }
}

export async function deleteConversation(id: string): Promise<void> {
  try {
    await puter.kv.del(getConvKey(id));
    const index = await getConversationsIndex();
    const filtered = index.filter(c => c.id !== id);
    await puter.kv.set(CONVERSATIONS_INDEX_KEY, JSON.stringify(filtered));
  } catch (_e) {
    localStorage.removeItem(getConvKey(id));
    const raw = localStorage.getItem(CONVERSATIONS_INDEX_KEY);
    const index: any[] = raw ? JSON.parse(raw) : [];
    const filtered = index.filter(c => c.id !== id);
    localStorage.setItem(CONVERSATIONS_INDEX_KEY, JSON.stringify(filtered));
  }
}

export function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
}
