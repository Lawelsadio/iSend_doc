import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Index from "./pages/Index";
import NotFound from "./pages/NotFound";
import DocumentAccess from "./components/recipient/DocumentAccess";
import SecureViewer from "./components/recipient/SecureViewer";
import DocumentError from "./components/recipient/DocumentError";
import AccessConfirmation from "./components/recipient/AccessConfirmation";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <Routes>
          <Route path="/" element={<Index />} />
          {/* Routes pour les destinataires */}
          <Route path="/d/:token" element={<DocumentAccess />} />
          <Route path="/d/:token/view" element={<SecureViewer />} />
          <Route path="/d/:token/error" element={<DocumentError />} />
          <Route path="/d/:token/confirmation" element={<AccessConfirmation />} />
          {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
          <Route path="*" element={<NotFound />} />
        </Routes>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
