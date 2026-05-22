import ChatPage from "@/components/ChatPage";

const Index = () => {
  return <ChatPage userName="صديقي" onSignOut={() => window.location.reload()} />;
};

export default Index;
