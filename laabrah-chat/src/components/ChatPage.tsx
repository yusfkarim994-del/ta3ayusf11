import { useState, useRef, useEffect, useCallback } from "react";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { Send, Menu, LogOut, Loader2 } from "lucide-react";
import ChatSidebar from "@/components/ChatSidebar";
import { SYSTEM_PROMPT } from "@/lib/systemPrompt";
import {
  type ChatMessage,
  type Conversation,
  saveConversation,
  loadConversation,
  generateId,
} from "@/lib/chatStorage";

interface ChatPageProps {
  userName: string;
  onSignOut: () => void;
}

const ChatPage = ({ userName, onSignOut }: ChatPageProps) => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [currentConvId, setCurrentConvId] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [refreshTrigger, setRefreshTrigger] = useState(0);
  const scrollRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = useCallback(() => {
    setTimeout(() => {
      if (scrollRef.current) {
        scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
      }
    }, 50);
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, scrollToBottom]);

  useEffect(() => {
    if (typeof puter !== 'undefined' && !puter.auth.isSignedIn()) {
      puter.auth.signIn();
    }
  }, []);

  const saveCurrentConversation = useCallback(
    async (msgs: ChatMessage[], convId: string) => {
      const title =
        msgs.find((m) => m.role === "user")?.content.slice(0, 50) || "محادثة جديدة";
      const conv: Conversation = {
        id: convId,
        title,
        messages: msgs,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };
      await saveConversation(conv);
      setRefreshTrigger((p) => p + 1);
    },
    []
  );

  const handleSend = async () => {
    const text = input.trim();
    if (!text || isLoading) return;

    const convId = currentConvId || generateId();
    if (!currentConvId) setCurrentConvId(convId);

    const userMsg: ChatMessage = { role: "user", content: text };
    const newMessages = [...messages, userMsg];
    setMessages(newMessages);
    setInput("");
    setIsLoading(true);

    // Build messages array for API
    const apiMessages = [
      { role: "system", content: SYSTEM_PROMPT },
      ...newMessages.map((m) => ({ role: m.role, content: m.content })),
    ];

    try {
      const response = await puter.ai.chat(apiMessages, {
        model: "gemini-2.5-flash",
        stream: true,
      });

      let assistantText = "";
      setMessages([...newMessages, { role: "assistant", content: "" }]);

      for await (const chunk of response) {
        if (chunk?.text) {
          assistantText += chunk.text;
          setMessages([
            ...newMessages,
            { role: "assistant", content: assistantText },
          ]);
        }
      }

      const finalMessages = [
        ...newMessages,
        { role: "assistant" as const, content: assistantText },
      ];
      setMessages(finalMessages);
      await saveCurrentConversation(finalMessages, convId);
    } catch (err) {
      console.error("AI Error:", err);
      const errorMsg: ChatMessage = {
        role: "assistant",
        content: "عذرا حصل خطا حاول مرة ثانية",
      };
      setMessages([...newMessages, errorMsg]);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleNewChat = () => {
    setMessages([]);
    setCurrentConvId(null);
    setInput("");
  };

  const handleSelectConversation = async (id: string) => {
    const conv = await loadConversation(id);
    if (conv) {
      setMessages(conv.messages);
      setCurrentConvId(conv.id);
    }
  };

  return (
    <div className="flex h-screen w-full bg-background">
      {/* Sidebar */}
      <ChatSidebar
        currentConvId={currentConvId}
        onSelectConversation={handleSelectConversation}
        onNewChat={handleNewChat}
        refreshTrigger={refreshTrigger}
        isOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
      />

      {/* Main Chat Area */}
      <div className="flex flex-1 flex-col min-w-0">
        {/* Header */}
        <header className="flex items-center justify-between border-b border-border px-4 py-3 bg-card/50 backdrop-blur-sm">
          <div className="flex items-center gap-3">
            <Button
              variant="ghost"
              size="icon"
              onClick={() => setSidebarOpen(true)}
              className="md:hidden"
            >
              <Menu className="h-5 w-5" />
            </Button>
            <div>
              <h1 className="font-semibold text-foreground text-base">
                ڕاوێژکاری دەروونی
              </h1>
              <p className="text-xs text-muted-foreground">مرحبا {userName}</p>
            </div>
          </div>
          <Button
            variant="ghost"
            size="sm"
            onClick={onSignOut}
            className="text-muted-foreground hover:text-destructive"
          >
            <LogOut className="h-4 w-4 ml-1" />
            خروج
          </Button>
        </header>

        {/* Messages */}
        <div ref={scrollRef} className="flex-1 overflow-y-auto">
          <div className="max-w-3xl mx-auto px-4 py-6 space-y-4">
            {messages.length === 0 && (
              <div className="flex flex-col items-center justify-center h-[60vh] text-center">
                <div className="h-20 w-20 rounded-full bg-primary/10 flex items-center justify-center mb-4">
                  <span className="text-3xl">💚</span>
                </div>
                <h2 className="text-xl font-semibold text-foreground mb-2">
                  اهلا وسهلا {userName}
                </h2>
                <p className="text-muted-foreground text-sm max-w-sm leading-relaxed">
                  انا هنا عشان اساعدك واسمعك بكل اهتمام
                  <br />
                  تقدر تكلمني عن اي شي يشغل بالك
                </p>
              </div>
            )}

            {messages.map((msg, i) => (
              <div
                key={i}
                className={`flex ${
                  msg.role === "user" ? "justify-start" : "justify-end"
                }`}
              >
                <div
                  className={`max-w-[85%] md:max-w-[75%] rounded-2xl px-4 py-3 text-sm leading-relaxed whitespace-pre-wrap ${
                    msg.role === "user"
                      ? "bg-primary text-primary-foreground rounded-tr-sm"
                      : "bg-[hsl(var(--ai-bubble))] text-foreground rounded-tl-sm"
                  }`}
                >
                  {msg.content}
                  {msg.role === "assistant" && msg.content === "" && isLoading && (
                    <span className="inline-flex gap-1">
                      <span className="animate-pulse">.</span>
                      <span className="animate-pulse delay-100">.</span>
                      <span className="animate-pulse delay-200">.</span>
                    </span>
                  )}
                </div>
              </div>
            ))}

            {isLoading && messages[messages.length - 1]?.role === "user" && (
              <div className="flex justify-end">
                <div className="bg-[hsl(var(--ai-bubble))] text-foreground rounded-2xl rounded-tl-sm px-4 py-3">
                  <Loader2 className="h-5 w-5 animate-spin text-primary" />
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Input */}
        <div className="border-t border-border bg-card/50 backdrop-blur-sm p-4">
          <div className="max-w-3xl mx-auto flex gap-2 items-end">
            <Textarea
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="اكتب رسالتك هنا..."
              className="resize-none min-h-[48px] max-h-32 text-sm bg-background"
              rows={1}
              disabled={isLoading}
            />
            <Button
              onClick={handleSend}
              disabled={!input.trim() || isLoading}
              size="icon"
              className="h-12 w-12 shrink-0 rounded-xl"
            >
              <Send className="h-5 w-5" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default ChatPage;
