/// <reference types="vite/client" />

/* eslint-disable @typescript-eslint/no-explicit-any */
interface PuterAuth {
  signIn: () => Promise<void>;
  signOut: () => Promise<void>;
  isSignedIn: () => boolean;
  getUser: () => Promise<{ username?: string; email?: string } | null>;
}

interface PuterAI {
  chat: (
    messages: string | Array<{ role: string; content: string }>,
    options?: {
      model?: string;
      stream?: boolean;
    }
  ) => Promise<any>;
}

interface PuterKV {
  set: (key: string, value: string) => Promise<void>;
  get: (key: string) => Promise<string | null>;
  del: (key: string) => Promise<void>;
  list: (options?: { prefix?: string }) => Promise<string[]>;
}

interface Puter {
  auth: PuterAuth;
  ai: PuterAI;
  kv: PuterKV;
  print: (content: any) => void;
}

declare const puter: Puter;
