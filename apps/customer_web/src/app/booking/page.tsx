"use client";

import { useState, useEffect, Suspense, useRef, useMemo } from "react";
import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { motion, AnimatePresence } from "framer-motion";
import { 
  ShieldCheck, ArrowLeft, ArrowRight, CheckCircle2, 
  MapPin, Calendar, CreditCard, Clock, Check, ShieldAlert, Sparkles,
  Layers, Zap, ChevronLeft, ChevronRight, Home, Wrench, Wind, Armchair, 
  AppWindow, Bug, RefreshCw, Plus, Building, Navigation
} from "lucide-react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import { supabase } from "@/lib/supabase";
import { GEOGRAPHIC_HIERARCHY } from "@/lib/geo";

// Step titles
const STEPS = ["حساب السعر", "اختيار الموعد", "العنوان", "المراجعة والتأكيد"];

const formatDateLocal = (date: Date): string => {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
};

// Helper fallback icon
function getServiceFallbackIcon(title: string) {
  const t = (title || "").toLowerCase();
  if (t.includes("تشطيب") || t.includes("بعد التشطيب") || t.includes("عميق") || t.includes("نظافة")) return Sparkles;
  if (t.includes("أثاث") || t.includes("كنب") || t.includes("سجاد") || t.includes("مفروشات") || t.includes("مجالس")) return Armchair;
  if (t.includes("زجاج") || t.includes("واجهات") || t.includes("شبابيك")) return AppWindow;
  if (t.includes("تكييف") || t.includes("تبريد") || t.includes("فريون")) return Wind;
  if (t.includes("سباكة") || t.includes("صيانة") || t.includes("كهرباء")) return Wrench;
  if (t.includes("حشرات") || t.includes("مكافحة") || t.includes("إبادة") || t.includes("تعقيم")) return Bug;
  return Home;
}

// Helper to resolve service icon path from Supabase storage or URLs
function resolveIconUrl(imageStr?: string | null): string | null {
  if (!imageStr || typeof imageStr !== "string") return null;
  const clean = imageStr.trim();
  if (!clean) return null;
  if (clean.startsWith("http://") || clean.startsWith("https://") || clean.startsWith("/")) {
    return clean;
  }
  const { data } = supabase.storage.from("service_images").getPublicUrl(clean);
  return data?.publicUrl || null;
}

// Robust fallback services tree matching database schema
const FALLBACK_SERVICES_TREE = [
  {
    id: "FH-S-100001",
    parent_id: null,
    title: { ar: "خدمات النظافة الشاملة" },
    description: { ar: "حلول تنظيف متكاملة للمنازل والمفروشات والواجهات بمعدات احترافية." },
    image: null,
    status: "active",
    is_bookable: false,
    sort_order: 1,
  },
  {
    id: "FH-S-100002",
    parent_id: null,
    title: { ar: "خدمات الصيانة والتشغيل" },
    description: { ar: "فنيون متخصصون لصيانة التكييفات والسباكة والكهرباء مع ضمان الجودة." },
    image: null,
    status: "active",
    is_bookable: false,
    sort_order: 2,
  },
  {
    id: "FH-S-100003",
    parent_id: null,
    title: { ar: "مكافحة الحشرات والتعقيم" },
    description: { ar: "إبادة فورية وآمنة 100% لكافة أنواع الحشرات والقوارض بضمان معتمد." },
    image: null,
    status: "active",
    is_bookable: false,
    sort_order: 3,
  },
  // Sub-services under Cleaning
  {
    id: "FH-S-100009",
    parent_id: "FH-S-100001",
    title: { ar: "تنظيف بعد التشطيب" },
    description: { ar: "إزالة آثار الدهانات والجبس وتنظيف الأرضيات والواجهات باحترافية كاملة." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 1,
    price_config: {
      fields: [
        { id: "area", label: { ar: "مساحة الشقة / الوحدة" }, type: "number", min: 50, max: 500, unit: "م²", required: true },
        { id: "rooms_count", label: { ar: "عدد الغرف" }, type: "number", min: 1, max: 10, required: true },
        { id: "bathrooms_count", label: { ar: "عدد الحمامات" }, type: "number", min: 1, max: 6, required: true },
        { id: "has_balcony", label: { ar: "هل توجد شرفات / بلكونات؟" }, type: "toggle", required: false }
      ],
      options: [
        { key: "تلميع باركيه بمواد خاصة", value: 150 },
        { key: "غسيل واجهات زجاجية خارجية", value: 200 }
      ]
    }
  },
  {
    id: "FH-S-100010",
    parent_id: "FH-S-100001",
    title: { ar: "التنظيف العميق" },
    description: { ar: "تنظيف شامل ودقيق لكل أركان المنزل والمطابخ والحمامات والأسطح." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 2,
    price_config: {
      fields: [
        { id: "area", label: { ar: "المساحة التقريبية" }, type: "number", min: 50, max: 400, unit: "م²", required: true },
        { id: "rooms_count", label: { ar: "عدد الغرف" }, type: "number", min: 1, max: 8, required: true },
        { id: "bathrooms_count", label: { ar: "عدد الحمامات" }, type: "number", min: 1, max: 5, required: true }
      ],
      options: [
        { key: "تنظيف وتعقيم أجهزة المطبخ الداخلية", value: 180 },
        { key: "تطهير وتعقيم إضافي بالبخار", value: 150 }
      ]
    }
  },
  {
    id: "FH-S-100011",
    parent_id: "FH-S-100001",
    title: { ar: "تنظيف الأثاث والمفروشات" },
    description: { ar: "غسيل وتعقيم الكنب، السجاد، المراتب والستائر بالبخار ومواد خاصة." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 3,
    price_config: {
      fields: [
        { id: "sofas_count", label: { ar: "عدد أطقم الكنب / المجالس" }, type: "number", min: 1, max: 6, required: true },
        { id: "carpets_count", label: { ar: "عدد قطع السجاد" }, type: "number", min: 0, max: 12, required: false },
        { id: "mattresses_count", label: { ar: "عدد المراتب" }, type: "number", min: 0, max: 8, required: false }
      ],
      options: [
        { key: "تعطير فندقي يدوم طويلاً", value: 100 },
        { key: "معالجة بقع مستعصية بمواد إيطالية", value: 150 }
      ]
    }
  },
  {
    id: "FH-S-100012",
    parent_id: "FH-S-100001",
    title: { ar: "التنظيف الدوري" },
    description: { ar: "زيارات تنظيف منتظمة بأفضل الأسعار للحفاظ على رونق ونظافة بيتك." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 4,
    price_config: {
      fields: [
        { id: "area", label: { ar: "المساحة التقريبية" }, type: "number", min: 50, max: 350, unit: "م²", required: true },
        { id: "hours_count", label: { ar: "عدد الساعات المطلوبة" }, type: "number", min: 3, max: 10, required: true }
      ]
    }
  },
  {
    id: "FH-S-100013",
    parent_id: "FH-S-100001",
    title: { ar: "تنظيف الواجهات والشبابيك" },
    description: { ar: "تلميع وتنظيف الواجهات والشبابيك والزجاج الداخلي والخارجي بلمعان فائق." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 5,
    price_config: {
      fields: [
        { id: "windows_count", label: { ar: "عدد الشبابيك / الواجهات" }, type: "number", min: 2, max: 20, required: true }
      ]
    }
  },
  // Sub-services under Maintenance
  {
    id: "FH-S-100020",
    parent_id: "FH-S-100002",
    title: { ar: "صيانة وتنظيف التكييف" },
    description: { ar: "غسيل الفلاتر، شحن الفريون، صيانة الوحدات الداخلية والخارجية." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 1,
    price_config: {
      fields: [
        { id: "ac_units_count", label: { ar: "عدد أجهزة التكييف" }, type: "number", min: 1, max: 10, required: true },
        { id: "needs_freon", label: { ar: "هل تحتاج شحن فريون؟" }, type: "toggle", required: false }
      ]
    }
  },
  {
    id: "FH-S-100021",
    parent_id: "FH-S-100002",
    title: { ar: "السباكة والأدوات الصحية" },
    description: { ar: "كشف تسريبات المياه، صيانة وتأسيس شبكات الصرف الصحي والسباكة." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 2,
    price_config: {
      fields: [
        { id: "units_count", label: { ar: "عدد النقاط / الأماكن المراد فحصها وصيانتها" }, type: "number", min: 1, max: 10, required: true }
      ]
    }
  },
  {
    id: "FH-S-100022",
    parent_id: "FH-S-100002",
    title: { ar: "الصيانة والكهرباء العامة" },
    description: { ar: "إصلاح الأعطال الكهربائية المنزلية وتركيب الإضاءة والأجهزة بأمان تام." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 3,
    price_config: {
      fields: [
        { id: "points_count", label: { ar: "عدد المفاتيح أو نقاط الإضاءة المراد صيانتها" }, type: "number", min: 1, max: 15, required: true }
      ]
    }
  },
  // Sub-services under Pest Control
  {
    id: "FH-S-100030",
    parent_id: "FH-S-100003",
    title: { ar: "إبادة ومكافحة الحشرات" },
    description: { ar: "مكافحة النمل الأبيض، الصراصير، البق، والقوارض بأحدث الأمصال الألمانية." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 1,
    price_config: {
      fields: [
        { id: "area", label: { ar: "مساحة الوحدة التقريبية" }, type: "number", min: 50, max: 400, unit: "م²", required: true },
        { id: "rooms_count", label: { ar: "عدد الغرف" }, type: "number", min: 1, max: 8, required: true }
      ]
    }
  },
  {
    id: "FH-S-100031",
    parent_id: "FH-S-100003",
    title: { ar: "التعقيم والتطهير الشامل" },
    description: { ar: "تطهير المنازل والمكاتب من البكتيريا والفيروسات بمطهرات طبية آمنة." },
    image: null,
    status: "active",
    is_bookable: true,
    sort_order: 2,
    price_config: {
      fields: [
        { id: "area", label: { ar: "المساحة المراد تعقيمها" }, type: "number", min: 50, max: 500, unit: "م²", required: true }
      ]
    }
  }
];

function BookingFlowContent() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  // URL params pre-selection
  const initialServiceId = searchParams.get("serviceId") || "";
  const initialSubServiceId = searchParams.get("subServiceId") || "";

  // State Management
  const [currentStep, setCurrentStep] = useState(0);
  const [subServiceId, setSubServiceId] = useState(initialSubServiceId);

  // Tree Nodes State with initial fallback tree
  const [allTreeServices, setAllTreeServices] = useState<any[]>(FALLBACK_SERVICES_TREE);
  const [selectedPath, setSelectedPath] = useState<any[]>([]);
  const [selectedSubService, setSelectedSubService] = useState<any>(null);
  const [loadingServices, setLoadingServices] = useState(false);

  // Dynamic Pricing Form Inputs
  const [pricingInputs, setPricingInputs] = useState<Record<string, any>>({});
  const [selectedAddons, setSelectedAddons] = useState<string[]>([]);
  
  // Schedule Address & Phone States (Address System V2)
  const [scheduledDate, setScheduledDate] = useState("");
  const [scheduledTime, setScheduledTime] = useState("");
  const [manualDateText, setManualDateText] = useState("");
  
  const [address, setAddress] = useState({
    governorate: "القاهرة",
    city: "التجمع الخامس",
    district: "الحي الأول",
    street_or_compound: "",
    building_identifier: "",
    floor: "",
    apartment_or_unit: "",
    landmark: ""
  });
  const [customDistrict, setCustomDistrict] = useState("");
  
  // Saved Addresses for Logged In User
  const [savedAddresses, setSavedAddresses] = useState<any[]>([]);
  const [selectedAddressMode, setSelectedAddressMode] = useState<"saved" | "new">("new");
  const [selectedSavedAddressId, setSelectedSavedAddressId] = useState<string | null>(null);

  const [phone, setPhone] = useState("");
  const [name, setName] = useState("");
  const [paymentMethod, setPaymentMethod] = useState("cash");

  const [loginRedirectUrl, setLoginRedirectUrl] = useState("/login");
  const [isClientUserLoggedIn, setIsClientUserLoggedIn] = useState(false);

  // Pricing calculation state
  const [isCalculating, setIsCalculating] = useState(false);
  const [hasCalculated, setHasCalculated] = useState(false);
  const [validationErrors, setValidationErrors] = useState<Record<string, string>>({});
  const [priceDetails, setPriceDetails] = useState({
    basePrice: 0,
    extraFees: 0,
    discount: 0,
    total: 0,
    metadata: {}
  });
  const [animatePrice, setAnimatePrice] = useState(false);
  const [isSubmittingBooking, setIsSubmittingBooking] = useState(false);
  const [availabilityMap, setAvailabilityMap] = useState<Record<string, boolean>>({});
  const [isLoadingAvailability, setIsLoadingAvailability] = useState(false);
  const [showMobilePriceModal, setShowMobilePriceModal] = useState(false);
  const dateScrollRef = useRef<HTMLDivElement>(null);

  // Load user profile details and saved addresses if logged in
  useEffect(() => {
    if (typeof window !== "undefined") {
      setLoginRedirectUrl(`/login?redirect=${encodeURIComponent(window.location.pathname + window.location.search)}`);
    }

    async function loadUserProfile() {
      try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session?.user) {
          setIsClientUserLoggedIn(true);
          const userId = session.user.id;
          
          try {
            const { data: profileData } = await supabase
              .from("profiles")
              .select("first_name, last_name")
              .eq("id", userId)
              .single();
            
            if (profileData?.first_name) {
              setName(`${profileData.first_name} ${profileData.last_name || ""}`.trim());
            } else {
              const metadata = session.user.user_metadata;
              if (metadata?.first_name) {
                setName(`${metadata.first_name} ${metadata.last_name || ""}`.trim());
              }
            }
          } catch {
            const metadata = session.user.user_metadata;
            if (metadata?.first_name) {
              setName(`${metadata.first_name} ${metadata.last_name || ""}`.trim());
            }
          }

          try {
            const { data: phoneData } = await supabase
              .from("user_phones")
              .select("phone_number")
              .eq("user_id", userId)
              .eq("is_primary", true)
              .maybeSingle();
            if (phoneData?.phone_number) {
              setPhone(phoneData.phone_number);
            }
          } catch {
            // ignore
          }

          // Fetch all saved user addresses (Address V2)
          try {
            const { data: addrData } = await supabase
              .from("user_addresses")
              .select("*")
              .eq("user_id", userId)
              .is("deleted_at", null)
              .order("is_primary", { ascending: false });
            
            if (addrData && addrData.length > 0) {
              setSavedAddresses(addrData);
              const primary = addrData.find((a: any) => a.is_primary) || addrData[0];
              setSelectedSavedAddressId(primary.id);
              setSelectedAddressMode("saved");
              
              setAddress({
                governorate: primary.governorate || "القاهرة",
                city: primary.city || "التجمع الخامس",
                district: primary.district || "الحي الأول",
                street_or_compound: primary.street_or_compound || primary.street || "",
                building_identifier: primary.building_identifier || primary.building_number || "",
                floor: primary.floor || "",
                apartment_or_unit: primary.apartment_or_unit || primary.apartment || "",
                landmark: primary.landmark || ""
              });
            }
          } catch {
            // ignore
          }
        }
      } catch {
        // ignore
      }
    }

    loadUserProfile();
  }, []);

  // Helper to build ancestry path
  const buildPathForNode = (nodeId: string, nodes: any[]): any[] => {
    const path: any[] = [];
    let current = nodes.find(n => n.id === nodeId);
    while (current) {
      path.unshift(current);
      if (!current.parent_id) break;
      current = nodes.find(n => n.id === current.parent_id);
    }
    return path;
  };

  // 1. Fetch Complete Active Services Tree with Fallback
  useEffect(() => {
    async function fetchCompleteServicesTree() {
      try {
        const { data, error } = await supabase
          .from("active_services_tree")
          .select("*")
          .order("sort_order", { ascending: true });
        
        const nodes = (data && data.length > 0) ? data : FALLBACK_SERVICES_TREE;
        setAllTreeServices(nodes);

        // Check URL query initialization
        if (initialSubServiceId) {
          const target = nodes.find((n: any) => n.id === initialSubServiceId);
          if (target) {
            setSelectedSubService(target);
            setSubServiceId(target.id);
            const path = buildPathForNode(target.id, nodes);
            setSelectedPath(path.slice(0, -1));
          }
        } else if (initialServiceId) {
          const rootTarget = nodes.find((n: any) => n.id === initialServiceId);
          if (rootTarget) {
            setSelectedPath([rootTarget]);
          }
        }
      } catch (e) {
        console.warn("Using fallback services tree for booking flow:", e);
        if (initialSubServiceId) {
          const target = FALLBACK_SERVICES_TREE.find((n: any) => n.id === initialSubServiceId);
          if (target) {
            setSelectedSubService(target);
            setSubServiceId(target.id);
            const path = buildPathForNode(target.id, FALLBACK_SERVICES_TREE);
            setSelectedPath(path.slice(0, -1));
          }
        } else if (initialServiceId) {
          const rootTarget = FALLBACK_SERVICES_TREE.find((n: any) => n.id === initialServiceId);
          if (rootTarget) {
            setSelectedPath([rootTarget]);
          }
        }
      } finally {
        setLoadingServices(false);
      }
    }
    fetchCompleteServicesTree();
  }, [initialServiceId, initialSubServiceId]);

  // Children and Leaf Node helpers
  const getChildren = (parentId: string | null) => {
    return allTreeServices.filter(s => s.parent_id === parentId);
  };

  // Current level nodes based on selectedPath
  const currentParent = selectedPath.length > 0 ? selectedPath[selectedPath.length - 1] : null;
  const currentLevelNodes = useMemo(() => {
    if (!currentParent) {
      return allTreeServices.filter(s => s.parent_id === null);
    }
    return allTreeServices.filter(s => s.parent_id === currentParent.id);
  }, [allTreeServices, currentParent]);

  // 2. Fetch availability when subServiceId is active
  useEffect(() => {
    async function fetchAvailability() {
      if (!subServiceId || subServiceId.includes("mock")) return;
      setIsLoadingAvailability(true);
      try {
        const today = new Date();
        const startDateStr = formatDateLocal(today);
        const endDate = new Date();
        endDate.setDate(today.getDate() + 30);
        const endDateStr = formatDateLocal(endDate);

        const { data, error } = await supabase.rpc("get_available_days", {
          p_sub_service_id: subServiceId,
          p_start_date: startDateStr,
          p_end_date: endDateStr
        });

        if (error) throw error;
        
        const availability: Record<string, boolean> = {};
        if (data) {
          data.forEach((item: any) => {
            availability[item.available_date] = item.is_available;
          });
        }
        setAvailabilityMap(availability);
      } catch (err) {
        console.error("Error fetching availability:", err);
      } finally {
        setIsLoadingAvailability(false);
      }
    }
    fetchAvailability();
  }, [subServiceId]);

  // 3. Initialize pricing input schema defaults when sub-service changes
  useEffect(() => {
    if (selectedSubService?.price_config?.fields) {
      const defaults: Record<string, any> = {};
      selectedSubService.price_config.fields.forEach((field: any) => {
        if (field.type === "number") {
          defaults[field.id] = "";
        } else if (field.type === "toggle") {
          defaults[field.id] = false;
        }
      });
      setPricingInputs(defaults);
      setSelectedAddons([]);
      setHasCalculated(false);
      setAnimatePrice(false);
      setValidationErrors({});
    }
  }, [selectedSubService]);

  // 4. Calculate Price RPC Call
  const handleCalculate = async () => {
    if (!subServiceId || subServiceId.includes("mock")) return;

    const errors: Record<string, string> = {};
    const adjustedInputs = { ...pricingInputs };
    let hasAdjustments = false;

    if (selectedSubService?.price_config?.fields) {
      selectedSubService.price_config.fields.forEach((field: any) => {
        const val = pricingInputs[field.id];
        const isRequired = field.required === true;
        
        if (isRequired) {
          if (val === undefined || val === null || val === "" || val === 0 || val === "0") {
            errors[field.id] = "هذا الحقل مطلوب ولا يمكن تركه فارغاً أو بقيمة صفر";
          } else if (field.type === "number") {
            const num = Number(val);
            if (field.min !== undefined && num < field.min) {
              adjustedInputs[field.id] = field.min;
              hasAdjustments = true;
            } else if (field.max !== undefined && num > field.max) {
              errors[field.id] = `الحد الأقصى المسموح به هو ${field.max}`;
            }
          }
        } else {
          if (val !== undefined && val !== null && val !== "" && field.type === "number" && val !== 0 && val !== "0") {
            const num = Number(val);
            if (field.min !== undefined && num < field.min && num > 0) {
              adjustedInputs[field.id] = field.min;
              hasAdjustments = true;
            } else if (field.max !== undefined && num > field.max) {
              errors[field.id] = `الحد الأقصى المسموح به هو ${field.max}`;
            }
          }
        }
      });
    }

    if (hasAdjustments) {
      setPricingInputs(adjustedInputs);
    }

    if (Object.keys(errors).length > 0) {
      setValidationErrors(errors);
      const firstErrorKey = Object.keys(errors)[0];
      const errorEl = document.getElementById(`field-container-${firstErrorKey}`);
      if (errorEl) {
        errorEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
      }
      return;
    }

    setValidationErrors({});
    setIsCalculating(true);

    const inputs = { ...adjustedInputs };
    Object.keys(inputs).forEach(key => {
      if (inputs[key] === "" || inputs[key] === undefined || inputs[key] === null) {
        delete inputs[key];
      }
    });

    if (selectedAddons.length > 0) {
      inputs.selected_options = selectedAddons;
    }

    try {
      const { data, error } = await supabase.rpc("calculate_booking_price", {
        p_sub_service_id: subServiceId,
        p_pricing_inputs: inputs
      });

      if (error) throw error;
      if (data) {
        setPriceDetails({
          basePrice: Number(data.basePrice) || 0,
          extraFees: Number(data.extraFees) || 0,
          discount: Number(data.discount) || 0,
          total: Number(data.total) || 0,
          metadata: data.metadata || {}
        });
        setHasCalculated(true);
        setTimeout(() => {
          setAnimatePrice(true);
        }, 50);

        if (typeof window !== "undefined" && window.innerWidth < 1024) {
          setShowMobilePriceModal(true);
        }
      }
    } catch (e: any) {
      console.error("Pricing calculation error:", e);
      alert(`فشل حساب السعر: ${e.message || JSON.stringify(e)}`);
    } finally {
      setIsCalculating(false);
    }
  };

  // Helper to parse manual date
  const parseManualDate = (text: string): Date | null => {
    const parts = text.trim().split(/[-\/]/);
    if (parts.length === 3) {
      let day = parseInt(parts[0]);
      let month = parseInt(parts[1]);
      let year = parseInt(parts[2]);
      
      if (parts[0].length === 4) {
        year = parseInt(parts[0]);
        day = parseInt(parts[2]);
      }
      
      if (!isNaN(day) && !isNaN(month) && !isNaN(year)) {
        if (month >= 1 && month <= 12 && day >= 1 && day <= 31 && year >= 1000) {
          const date = new Date(year, month - 1, day);
          if (date.getFullYear() === year && date.getMonth() === month - 1 && date.getDate() === day) {
            return date;
          }
        }
      }
    }
    return null;
  };

  const scrollDates = (direction: 'left' | 'right') => {
    if (dateScrollRef.current) {
      const scrollAmount = 200;
      dateScrollRef.current.scrollBy({
        left: direction === 'left' ? -scrollAmount : scrollAmount,
        behavior: 'smooth'
      });
    }
  };

  // Sync typed date input to scheduledDate
  useEffect(() => {
    if (manualDateText.trim() === "") {
      setScheduledDate("");
      return;
    }
    const parsedDate = parseManualDate(manualDateText);
    if (parsedDate) {
      const todayDate = new Date();
      todayDate.setHours(0, 0, 0, 0);
      if (parsedDate >= todayDate) {
        const diffTime = parsedDate.getTime() - todayDate.getTime();
        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
        if (diffDays <= 30) {
          const formatted = formatDateLocal(parsedDate);
          if (availabilityMap[formatted] !== false) {
            setScheduledDate(formatted);
            return;
          }
        }
      }
    }
    setScheduledDate("");
  }, [manualDateText, availabilityMap]);

  const handleToggleAddon = (id: string) => {
    if (selectedAddons.includes(id)) {
      setSelectedAddons(selectedAddons.filter((a) => a !== id));
    } else {
      setSelectedAddons([...selectedAddons, id]);
    }
    setHasCalculated(false);
    setAnimatePrice(false);
  };

  const handleFieldChange = (fieldId: string, val: any) => {
    setPricingInputs({
      ...pricingInputs,
      [fieldId]: val
    });
    setHasCalculated(false);
    setAnimatePrice(false);
    if (validationErrors[fieldId]) {
      const updatedErrors = { ...validationErrors };
      delete updatedErrors[fieldId];
      setValidationErrors(updatedErrors);
    }
  };

  // Step validation
  const isStepValid = () => {
    switch (currentStep) {
      case 0:
        return subServiceId !== "" && priceDetails.total > 0;
      case 1:
        return scheduledDate !== "" && scheduledTime !== "" && availabilityMap[scheduledDate] !== false;
      case 2: {
        const effDistrict = address.district === "أخرى" ? customDistrict.trim() : address.district.trim();
        return (
          address.governorate.trim() !== "" &&
          address.city.trim() !== "" &&
          effDistrict !== "" &&
          address.street_or_compound.trim() !== "" &&
          address.building_identifier.trim() !== ""
        );
      }
      case 3: {
        const phoneRegex = /^(010|011|012|015)\d{8}$/;
        return phoneRegex.test(phone.trim()) && name.trim() !== "";
      }
      default:
        return false;
    }
  };

  // Geographic changes handler
  const handleGovernorateChange = (gov: string) => {
    const defaultCity = Object.keys(GEOGRAPHIC_HIERARCHY[gov] || {})[0] || "";
    const defaultDistricts = GEOGRAPHIC_HIERARCHY[gov]?.[defaultCity] || [];
    const defaultDistrict = defaultDistricts[0] || "";
    setAddress({
      ...address,
      governorate: gov,
      city: defaultCity,
      district: defaultDistrict
    });
    setCustomDistrict("");
  };

  const handleCityChange = (c: string) => {
    const defaultDistricts = GEOGRAPHIC_HIERARCHY[address.governorate]?.[c] || [];
    const defaultDistrict = defaultDistricts[0] || "";
    setAddress({
      ...address,
      city: c,
      district: defaultDistrict
    });
    setCustomDistrict("");
  };

  // Selecting a saved address
  const handleSelectSavedAddress = (addr: any) => {
    setSelectedSavedAddressId(addr.id);
    setSelectedAddressMode("saved");
    setAddress({
      governorate: addr.governorate || "القاهرة",
      city: addr.city || "التجمع الخامس",
      district: addr.district || "الحي الأول",
      street_or_compound: addr.street_or_compound || addr.street || "",
      building_identifier: addr.building_identifier || addr.building_number || "",
      floor: addr.floor || "",
      apartment_or_unit: addr.apartment_or_unit || addr.apartment || "",
      landmark: addr.landmark || ""
    });
  };

  const handleNext = () => {
    if (currentStep < STEPS.length - 1) {
      setCurrentStep(currentStep + 1);
      if (typeof window !== "undefined") {
        setTimeout(() => {
          window.scrollTo({ top: 0, behavior: "smooth" });
        }, 80);
      }
    }
  };

  const handleBack = () => {
    if (currentStep > 0) {
      setCurrentStep(currentStep - 1);
      if (typeof window !== "undefined") {
        setTimeout(() => {
          window.scrollTo({ top: 0, behavior: "smooth" });
        }, 80);
      }
    }
  };

  // Complete Booking flow calling create_atomic_booking
  const handleCompleteBooking = async () => {
    setIsSubmittingBooking(true);
    try {
      let userId: string | null = null;
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        userId = session.user.id;
      }

      if (userId) {
        await supabase
          .from("user_phones")
          .insert({
            user_id: userId,
            phone_number: phone.trim(),
            is_primary: true,
            is_verified: true
          });
      }

      let time24 = "09:00:00";
      const timeClean = scheduledTime.replace(" ص", "").replace(" م", "").trim();
      const isPm = scheduledTime.includes("م");
      if (timeClean) {
        const parts = timeClean.split(":");
        let hour = parseInt(parts[0]);
        if (isPm && hour < 12) hour += 12;
        if (!isPm && hour === 12) hour = 0;
        time24 = `${hour.toString().padStart(2, '0')}:${parts[1] || '00'}:00`;
      }

      const finalDistrict = address.district === "أخرى" ? customDistrict.trim() : address.district.trim();

      // Address System V2 Snapshot Payload
      const addressSnapshot = {
        governorate: address.governorate,
        city: address.city,
        district: finalDistrict,
        street_or_compound: address.street_or_compound.trim(),
        building_identifier: address.building_identifier.trim(),
        floor: address.floor.trim(),
        apartment_or_unit: address.apartment_or_unit.trim(),
        landmark: address.landmark.trim(),
        // Legacy field aliases for backwards compatibility
        street: address.street_or_compound.trim(),
        building: address.building_identifier.trim(),
        apartment: address.apartment_or_unit.trim()
      };

      // Save new address to user profile if user is logged in
      if (userId && selectedAddressMode === "new") {
        try {
          await supabase.from("user_addresses").insert({
            user_id: userId,
            governorate: address.governorate,
            city: address.city,
            district: finalDistrict,
            street_or_compound: address.street_or_compound.trim(),
            building_identifier: address.building_identifier.trim(),
            floor: address.floor.trim() || null,
            apartment_or_unit: address.apartment_or_unit.trim() || null,
            landmark: address.landmark.trim() || null,
            is_primary: savedAddresses.length === 0
          });
        } catch (addrErr) {
          console.warn("Failed to persist address to profile:", addrErr);
        }
      }

      const serviceSnapshot = {
        title: selectedSubService?.title?.ar || selectedSubService?.title || "حجز خدمة فريش هوم"
      };

      const pricingPayload = {
        ...pricingInputs,
        payment_method: paymentMethod,
        selected_options: selectedAddons,
        phone: phone.trim(),
        name: name.trim()
      };

      const { data: bookingId, error: bookingError } = await supabase.rpc("create_atomic_booking", {
        p_user_id: userId,
        p_sub_service_id: subServiceId,
        p_technician_id: null,
        p_scheduled_day: scheduledDate,
        p_address_snapshot: addressSnapshot,
        p_service_snapshot: serviceSnapshot,
        p_pricing_inputs: pricingPayload,
        p_contact_name: name.trim(),
        p_contact_phones: [phone.trim()],
        p_start_time_slot: time24,
        p_is_whatsapp_confirmed: userId !== null
      });

      if (bookingError) throw bookingError;

      if (bookingId) {
        if (typeof window !== "undefined") {
          localStorage.setItem(`booking_created_${bookingId}`, new Date().toISOString());
        }
        router.push(`/orders?bookingId=${bookingId}&success=true`);
      } else {
        throw new Error("فشلت عملية إدراج الحجز في قاعدة البيانات.");
      }
    } catch (e: any) {
      console.error("Booking creation failed:", e);
      alert(`عذراً، حدث خطأ أثناء تأكيد حجزك: ${e.message || JSON.stringify(e)}`);
    } finally {
      setIsSubmittingBooking(false);
    }
  };

  // Service Hierarchy Navigation (Framer Motion Shared Element)
  const handleServiceNodeSelect = (node: any, isBookableLeaf: boolean) => {
    if (isBookableLeaf) {
      setSelectedSubService(node);
      setSubServiceId(node.id);
    } else {
      setSelectedPath(prev => [...prev, node]);
    }
  };

  const handleHierarchyBack = () => {
    if (selectedPath.length === 0) return;
    setSelectedPath(prev => prev.slice(0, -1));
  };

  const handleHierarchyBreadcrumbClick = (targetIdx: number) => {
    setSelectedPath(prev => prev.slice(0, targetIdx + 1));
  };

  const handleHierarchyReset = () => {
    setSelectedPath([]);
  };

  const springTransition = {
    type: "spring" as const,
    stiffness: 300,
    damping: 30,
  };

  return (
    <>
      <Header />
      
      <main className="flex-1 bg-[#F8FAFC] dark:bg-[#040A1C] py-8 sm:py-10 transition-colors duration-300">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Stepper progress */}
          <div className="sticky top-[72px] z-20 mb-6">
            <div className="max-w-xl mx-auto bg-white/95 dark:bg-[#071739]/95 backdrop-blur-md rounded-2xl px-4 py-2.5 border border-slate-200/80 dark:border-blue-900/50 shadow-xs">
              <div className="flex justify-between items-center relative">
                {STEPS.map((stepText, idx) => {
                  const isCompleted = idx < currentStep;
                  const isActive = idx === currentStep;
                  return (
                    <div key={idx} className="flex flex-col items-center z-10 flex-1 relative">
                      <div 
                        className={`w-6 h-6 sm:w-7 sm:h-7 rounded-full flex items-center justify-center font-bold text-[11px] sm:text-xs transition-all duration-300 ${
                          isCompleted ? "bg-[#2ECC71] text-white shadow-xs" : isActive ? "bg-[#0091FF] text-white scale-110 shadow-sm shadow-blue-500/25" : "bg-slate-100 dark:bg-slate-800 text-slate-400"
                        }`}
                      >
                        {isCompleted ? <Check className="w-3 h-3 sm:w-3.5 sm:h-3.5 stroke-[2.5]" /> : idx + 1}
                      </div>
                      <span className={`text-[10px] font-bold mt-1 hidden sm:block ${isActive ? "text-[#0091FF] dark:text-[#22A5FC] font-black" : "text-slate-400"}`}>
                        {stepText}
                      </span>
                    </div>
                  );
                })}
                
                {/* Connector line */}
                <div className="absolute left-6 right-6 top-[12px] sm:top-[14px] h-0.5 bg-slate-100 dark:bg-slate-800 -z-0">
                  <div 
                    className="h-full bg-[#2ECC71] transition-all duration-500" 
                    style={{ width: `${(currentStep / (STEPS.length - 1)) * 100}%` }}
                  ></div>
                </div>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
            {/* Step Content */}
            <motion.div 
              layout 
              transition={{ duration: 0.3 }} 
              className="lg:col-span-8 bg-white dark:bg-[#071739] rounded-3xl p-5 sm:p-7 border border-slate-200/80 dark:border-blue-900/50 shadow-sm min-h-[420px] flex flex-col justify-between transition-colors"
            >
              <AnimatePresence mode="wait">
                {/* STEP 1: HIERARCHICAL SELECTION & PRICING */}
                {currentStep === 0 && (
                  <motion.div
                    key="step-0"
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    transition={{ duration: 0.3, ease: "easeInOut" }}
                    className="space-y-6"
                  >
                    {loadingServices ? (
                      <div className="py-20 flex flex-col items-center justify-center space-y-3">
                        <div className="animate-spin rounded-full h-9 w-9 border-t-2 border-[#0091FF]"></div>
                        <span className="text-xs font-bold text-slate-400">جاري تحميل الخدمات وقواعد التسعير...</span>
                      </div>
                    ) : !selectedSubService ? (
                      /* 1. HIERARCHICAL TREE SELECTION MODE (SHARED ELEMENT FRAMER-MOTION) */
                      <div className="space-y-5">
                        
                        {/* Dynamic Parent Origin Transformation Banner */}
                        {selectedPath.length > 0 && currentParent ? (
                          <motion.div
                            layout
                            layoutId={`service-node-${currentParent.id}`}
                            transition={springTransition}
                            className="bg-gradient-to-r from-blue-50/90 via-sky-50/50 to-indigo-50/60 dark:from-[#050D24] dark:via-[#071739] dark:to-[#091E4A] p-4 sm:p-5 rounded-2xl border border-blue-200/90 dark:border-blue-900/60 shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-3.5"
                          >
                            {/* Parent Identity & Icon & Description */}
                            <div className="flex items-center gap-3.5 min-w-0">
                              <motion.div 
                                layout="position" 
                                layoutId={`service-icon-${currentParent.id}`}
                                className="w-12 h-12 sm:w-14 sm:h-14 rounded-2xl bg-white dark:bg-[#071739] border border-blue-200/80 dark:border-blue-800/60 text-[#0091FF] dark:text-[#22A5FC] flex items-center justify-center p-2.5 shrink-0 shadow-2xs"
                              >
                                {resolveIconUrl(currentParent.image) ? (
                                  <img src={resolveIconUrl(currentParent.image) || ""} alt="" className="w-full h-full object-contain" />
                                ) : (
                                  (() => {
                                    const IconComp = getServiceFallbackIcon(currentParent.title?.ar || currentParent.title || "");
                                    return <IconComp className="w-6 h-6 sm:w-7 sm:h-7" />;
                                  })()
                                )}
                              </motion.div>
                              <div className="min-w-0 space-y-0.5">
                                <motion.h3 
                                  layout="position"
                                  layoutId={`service-title-${currentParent.id}`}
                                  className="text-base sm:text-lg font-black text-slate-900 dark:text-white leading-tight"
                                >
                                  {currentParent.title?.ar || currentParent.title}
                                </motion.h3>
                                {(currentParent.description?.ar || currentParent.description) && (
                                  <motion.p 
                                    initial={{ opacity: 0 }}
                                    animate={{ opacity: 1 }}
                                    transition={{ delay: 0.15, duration: 0.25 }}
                                    className="text-xs text-slate-500 dark:text-slate-300 font-medium leading-relaxed line-clamp-2"
                                  >
                                    {currentParent.description?.ar || currentParent.description}
                                  </motion.p>
                                )}
                              </div>
                            </div>

                            {/* Back Button */}
                            <motion.button
                              initial={{ opacity: 0, scale: 0.9 }}
                              animate={{ opacity: 1, scale: 1 }}
                              transition={{ delay: 0.15, duration: 0.25 }}
                              type="button"
                              onClick={handleHierarchyBack}
                              className="self-start sm:self-center text-xs font-black text-slate-700 dark:text-slate-200 hover:text-[#0091FF] dark:hover:text-[#22A5FC] flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-white dark:bg-[#071739] border border-slate-200/90 dark:border-blue-900/60 transition-all shrink-0 cursor-pointer shadow-2xs hover:shadow-xs active:scale-95"
                            >
                              <ChevronRight className="w-4 h-4" />
                              <span>رجوع خطوة</span>
                            </motion.button>
                          </motion.div>
                        ) : null}

                        {/* Header Title based on Current Depth */}
                        <motion.div
                          key={selectedPath.length === 0 ? "root-title" : `child-title-${currentParent?.id}`}
                          initial={{ opacity: 0, y: 4 }}
                          animate={{ opacity: 1, y: 0 }}
                          transition={{ duration: 0.2 }}
                        >
                          {selectedPath.length === 0 ? (
                            <>
                              <span className="text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/60 inline-block mb-1.5">
                                الخطوة 1: اختيار الخدمة
                              </span>
                              <h2 className="text-xl sm:text-2xl font-black text-slate-900 dark:text-white">
                                برجاء تحديد نوع الخدمة المطلوبة
                              </h2>
                              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-1">
                                اختر القسم الرئيسي المناسب للبدء في تخصيص طلبك وتحديد السعر النهائي
                              </p>
                            </>
                          ) : (
                            <>
                              <h2 className="text-lg sm:text-xl font-black text-slate-900 dark:text-white">
                                يرجى اختيار الخدمة المناسبة
                              </h2>
                              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium mt-1">
                                اختر من الخدمات والخيارات التابعة لـ ({currentParent?.title?.ar || currentParent?.title}) أدناه
                              </p>
                            </>
                          )}
                        </motion.div>

                        {/* Grid of Minimal Interactive Service Cards (Staggered Animation with Shared Element layoutId) */}
                        <motion.div 
                          key={selectedPath.map((n) => n.id).join("-") || "root-level"}
                          className="grid grid-cols-2 sm:grid-cols-3 gap-3 sm:gap-4 pt-1"
                        >
                          {currentLevelNodes.map((node, idx) => {
                            const nodeChildren = getChildren(node.id);
                            const isBookableLeaf = node.is_bookable === true && nodeChildren.length === 0;
                            const isPaused = node.status === "paused";
                            const NodeIcon = getServiceFallbackIcon(node.title?.ar || node.title || "");
                            const iconUrl = resolveIconUrl(node.image);

                            return (
                              <motion.button
                                layout
                                layoutId={`service-node-${node.id}`}
                                initial={{ opacity: 0, scale: 0.94 }}
                                animate={{ opacity: 1, scale: 1 }}
                                exit={{ opacity: 0, scale: 0.94 }}
                                transition={{
                                  layout: springTransition,
                                  opacity: { duration: 0.22, delay: 0.1 + idx * 0.035 },
                                  scale: { duration: 0.22, delay: 0.1 + idx * 0.035 }
                                }}
                                type="button"
                                key={node.id}
                                disabled={isPaused}
                                onClick={() => handleServiceNodeSelect(node, isBookableLeaf)}
                                className={`p-3.5 sm:p-5 rounded-2xl border text-center flex flex-col items-center justify-center group cursor-pointer active:scale-95 shadow-2xs hover:shadow-md hover:-translate-y-0.5 relative ${
                                  isPaused
                                    ? "opacity-50 border-amber-200/90 dark:border-amber-900/50 bg-amber-50/20 dark:bg-amber-950/20 cursor-not-allowed"
                                    : "border-slate-200/90 dark:border-blue-900/50 bg-white dark:bg-[#071739] hover:border-[#0091FF] dark:hover:border-[#0091FF]"
                                }`}
                              >
                                {/* Top mini-badge for sub-branches or direct booking */}
                                {isPaused ? (
                                  <span className="absolute top-2.5 right-2.5 text-[9px] font-black px-1.5 py-0.5 rounded-md bg-amber-50 dark:bg-amber-950/80 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                                    متوقفة
                                  </span>
                                ) : nodeChildren.length > 0 ? (
                                  <span className="absolute top-2.5 right-2.5 text-[9px] font-black px-1.5 py-0.5 rounded-md bg-blue-50 dark:bg-blue-950/80 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/40">
                                    {nodeChildren.length}
                                  </span>
                                ) : null}

                                {/* Icon Badge */}
                                <motion.div 
                                  layout="position"
                                  layoutId={`service-icon-${node.id}`}
                                  className={`w-12 h-12 sm:w-14 sm:h-14 rounded-2xl ${
                                    isPaused 
                                      ? "bg-amber-50 dark:bg-amber-950/40 text-amber-500 border border-amber-200 dark:border-amber-900/40" 
                                      : "bg-blue-50/80 dark:bg-[#050D24] text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/50 group-hover:bg-[#0091FF] group-hover:text-white"
                                  } flex items-center justify-center p-2.5 group-hover:scale-105 transition-all shrink-0 shadow-2xs`}
                                >
                                  {iconUrl ? (
                                    <img src={iconUrl} alt="" className="w-full h-full object-contain" />
                                  ) : (
                                    <NodeIcon className="w-6 h-6 sm:w-7 sm:h-7" />
                                  )}
                                </motion.div>

                                {/* Service Title */}
                                <motion.h3 
                                  layout="position"
                                  layoutId={`service-title-${node.id}`}
                                  className="text-xs sm:text-sm font-black text-slate-900 dark:text-white group-hover:text-[#0091FF] dark:group-hover:text-[#22A5FC] transition-colors mt-2.5 leading-snug line-clamp-2"
                                >
                                  {node.title?.ar || node.title}
                                </motion.h3>
                              </motion.button>
                            );
                          })}
                        </motion.div>
                      </div>
                    ) : (
                      /* 2. DYNAMIC PRICING FORM MODE (Leaf Bookable Service Selected) */
                      <motion.div 
                        initial={{ opacity: 0, y: 20 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={springTransition}
                        className="space-y-6"
                      >
                      {/* Selected Service Banner with Full Path and Change Button */}
                      <motion.div 
                        layout
                        layoutId={`service-node-${selectedSubService.id}`}
                        transition={springTransition}
                        className="bg-gradient-to-r from-blue-50/90 to-indigo-50/60 dark:from-[#050D24] dark:to-[#071739] p-4 sm:p-5 rounded-2xl border border-blue-200/90 dark:border-blue-900/60 flex items-center justify-between gap-3 shadow-xs"
                      >
                        <div className="flex items-center gap-3 sm:gap-4 min-w-0">
                          <motion.div 
                            layout="position"
                            layoutId={`service-icon-${selectedSubService.id}`}
                            className="w-12 h-12 rounded-2xl bg-white dark:bg-[#071739] border border-blue-100 dark:border-blue-900/50 flex items-center justify-center text-[#0091FF] shrink-0 shadow-2xs"
                          >
                            {selectedSubService.image ? (
                              <img src={resolveIconUrl(selectedSubService.image) || ""} alt="" className="w-7 h-7 object-contain" />
                            ) : (
                              <Sparkles className="w-6 h-6" />
                            )}
                          </motion.div>
                          <div className="min-w-0">
                            <div className="text-[10px] font-extrabold text-[#0091FF] dark:text-[#22A5FC] flex items-center gap-1 truncate">
                              {buildPathForNode(selectedSubService.id, allTreeServices).map((p, i, arr) => (
                                <span key={p.id}>{p.title?.ar || p.title}{i < arr.length - 1 ? " / " : ""}</span>
                              ))}
                            </div>
                            <motion.h3 
                              layout="position"
                              layoutId={`service-title-${selectedSubService.id}`}
                              className="text-base sm:text-lg font-black text-slate-900 dark:text-white truncate mt-0.5"
                            >
                              {selectedSubService.title?.ar || selectedSubService.title}
                            </motion.h3>
                          </div>
                        </div>
                        
                        <motion.button
                          initial={{ opacity: 0, scale: 0.9 }}
                          animate={{ opacity: 1, scale: 1 }}
                          transition={{ delay: 0.15, duration: 0.25 }}
                          type="button"
                          onClick={() => {
                            setSelectedSubService(null);
                            setSubServiceId("");
                            setHasCalculated(false);
                            setAnimatePrice(false);
                          }}
                          className="px-3.5 py-2 rounded-xl bg-white dark:bg-[#071739] border border-slate-200 dark:border-blue-900/60 text-slate-700 dark:text-slate-200 hover:text-[#0091FF] hover:border-[#0091FF] text-xs font-black transition-all shrink-0 cursor-pointer shadow-2xs flex items-center gap-1.5"
                        >
                          <RefreshCw className="w-3 h-3" />
                          <span>تغيير الخدمة</span>
                        </motion.button>
                      </motion.div>

                      {/* Header */}
                      <div>
                        <h2 className="text-xl font-black text-slate-900 dark:text-white">
                          تعديل مواصفات وحساب تسعير الخدمة
                        </h2>
                        <p className="text-slate-500 dark:text-slate-400 text-xs font-medium mt-0.5">
                          أدخل المقاسات الحقيقية والتفاصيل للحصول على سعر نهائي دقيق وموثوق.
                        </p>
                      </div>

                      {/* Dynamic price input fields based on active catalog schema */}
                      {selectedSubService?.price_config?.fields && selectedSubService.price_config.fields.length > 0 ? (
                        <div className="space-y-4 pt-2 border-t border-slate-100 dark:border-blue-900/40">
                          {selectedSubService.price_config.fields.map((field: any) => {
                            const val = pricingInputs[field.id];
                            const hasError = !!validationErrors[field.id];
                            const hasIcon = field.icon && (field.icon.startsWith("http") || field.icon.startsWith("/"));

                            return (
                              <div 
                                key={field.id} 
                                id={`field-container-${field.id}`} 
                                className={`p-4 rounded-2xl border transition-all duration-200 bg-slate-50/50 dark:bg-[#050D24]/60 hover:bg-slate-50 dark:hover:bg-[#050D24] ${
                                  hasError ? "border-red-300 dark:border-red-900 bg-red-50/10" : "border-slate-200/80 dark:border-blue-900/40 hover:border-slate-300"
                                }`}
                              >
                                <div className="flex gap-4 items-start">
                                  {hasIcon && (
                                    <div className="w-12 h-12 rounded-xl bg-white dark:bg-[#071739] border border-slate-200/80 dark:border-blue-900/50 overflow-hidden flex items-center justify-center shrink-0 shadow-xs">
                                      <img 
                                        src={field.icon} 
                                        alt={field.label?.ar || field.label || ""} 
                                        className="w-full h-full object-contain p-0.5"
                                      />
                                    </div>
                                  )}
                                  
                                  <div className="flex-1 space-y-3 min-w-0">
                                    {/* Field Label & Description */}
                                    <div className="space-y-1">
                                      <div className="flex justify-between items-center">
                                        <label className="block text-xs font-black text-slate-800 dark:text-slate-200">
                                          {field.label?.ar || field.label} {field.unit ? `(${field.unit})` : ""}
                                          {!field.required && <span className="text-[9px] text-slate-400 font-bold mr-1.5">(اختياري)</span>}
                                        </label>
                                        
                                        {field.type === "number" && field.id === "area" && (
                                          <span className="text-xs font-black text-[#0091FF] bg-blue-50 dark:bg-blue-950/80 px-2 py-0.5 rounded-lg border border-blue-100 dark:border-blue-900/50">
                                            {val !== "" && val !== undefined && val !== null ? val : "0"} {field.unit || "م²"}
                                          </span>
                                        )}
                                      </div>
                                      {field.description?.ar && (
                                        <p className="text-[10px] text-slate-400 font-semibold leading-relaxed">
                                          {field.description.ar}
                                        </p>
                                      )}
                                    </div>

                                    {/* Input Controls */}
                                    <div className="pt-1">
                                      {field.type === "number" && (
                                        field.id === "area" ? (
                                          <div className="flex items-center gap-2">
                                            <button 
                                              type="button"
                                              onClick={() => {
                                                const currentVal = (val === "" || val === undefined || val === null) ? (field.min || 50) : Number(val);
                                                handleFieldChange(field.id, Math.max(field.min || 50, currentVal - 10));
                                              }}
                                              className="w-9 h-9 rounded-xl bg-slate-100 dark:bg-slate-800 border border-slate-200/60 dark:border-blue-900/50 font-extrabold text-slate-700 dark:text-slate-200 flex items-center justify-center hover:bg-slate-200 transition-colors cursor-pointer"
                                            >
                                              -
                                            </button>
                                            <div className="relative flex items-center max-w-[120px]">
                                              <input 
                                                type="number" 
                                                min={field.min || 50} 
                                                max={field.max || 400} 
                                                value={val ?? ""}
                                                onChange={(e) => {
                                                  const text = e.target.value;
                                                  if (text === "") {
                                                    handleFieldChange(field.id, "");
                                                  } else {
                                                    const parsed = parseInt(text);
                                                    handleFieldChange(field.id, isNaN(parsed) ? "" : parsed);
                                                  }
                                                }}
                                                onBlur={() => {
                                                  if (val !== "" && val !== undefined && val !== null) {
                                                    const num = Number(val);
                                                    if (field.min !== undefined && num < field.min) {
                                                      handleFieldChange(field.id, field.min);
                                                    }
                                                  }
                                                }}
                                                className={`w-full p-1.5 pl-7 rounded-xl border text-center text-xs font-black focus:outline-none bg-white dark:bg-[#071739] text-slate-900 dark:text-white font-sans [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none ${
                                                  hasError ? 'border-red-500 focus:border-red-500 bg-red-50/15' : 'border-slate-200 dark:border-blue-900/60 focus:border-[#0091FF]'
                                                }`}
                                              />
                                              <span className="absolute left-2 text-[8px] font-extrabold text-slate-400 pointer-events-none">
                                                {field.unit || "م²"}
                                              </span>
                                            </div>
                                            <button 
                                              type="button"
                                              onClick={() => {
                                                const currentVal = (val === "" || val === undefined || val === null) ? (field.min || 50) : Number(val);
                                                handleFieldChange(field.id, Math.min(field.max || 400, currentVal + 10));
                                              }}
                                              className="w-9 h-9 rounded-xl bg-slate-100 dark:bg-slate-800 border border-slate-200/60 dark:border-blue-900/50 font-extrabold text-slate-700 dark:text-slate-200 flex items-center justify-center hover:bg-slate-200 transition-colors cursor-pointer"
                                            >
                                              +
                                            </button>
                                          </div>
                                        ) : (
                                          <div className="flex items-center gap-3">
                                            <button 
                                              type="button"
                                              onClick={() => {
                                                const currentVal = (val === "" || val === undefined || val === null) ? 0 : Number(val);
                                                handleFieldChange(field.id, Math.max(field.min || 0, currentVal - 1));
                                              }}
                                              className="w-9 h-9 rounded-xl bg-slate-100 dark:bg-slate-800 border border-slate-200/60 dark:border-blue-900/50 font-extrabold text-slate-700 dark:text-slate-200 flex items-center justify-center hover:bg-slate-200 transition-all cursor-pointer"
                                            >
                                              -
                                            </button>
                                            <span className="text-sm font-black w-8 text-center text-slate-800 dark:text-white">
                                              {(val === "" || val === undefined || val === null) ? "0" : val}
                                            </span>
                                            <button 
                                              type="button"
                                              onClick={() => {
                                                const currentVal = (val === "" || val === undefined || val === null) ? 0 : Number(val);
                                                if (field.max !== undefined && currentVal >= field.max) return;
                                                handleFieldChange(field.id, currentVal + 1);
                                              }}
                                              className="w-9 h-9 rounded-xl bg-slate-100 dark:bg-slate-800 border border-slate-200/60 dark:border-blue-900/50 font-extrabold text-slate-700 dark:text-slate-200 flex items-center justify-center hover:bg-slate-200 transition-all cursor-pointer"
                                            >
                                              +
                                            </button>
                                          </div>
                                        )
                                      )}

                                      {field.type === "toggle" && (() => {
                                        const optTrue = field.options && field.options.length > 0
                                          ? field.options.find((o: any) => o.id === "true" || o.id === "yes")
                                          : null;
                                        const optFalse = field.options && field.options.length > 1
                                          ? field.options.find((o: any) => o.id === "false" || o.id === "no")
                                          : null;
                                        
                                        const trueLabel = optTrue?.label?.ar || optTrue?.label || "نعم";
                                        const falseLabel = optFalse?.label?.ar || optFalse?.label || "لا";
                                        
                                        const isTrueSelected = val === true;
                                        const isFalseSelected = val === false;
                                        
                                        return (
                                          <div className="grid grid-cols-2 gap-3 max-w-[280px]">
                                            <div 
                                              onClick={() => handleFieldChange(field.id, true)}
                                              className={`p-2.5 rounded-xl border flex items-center justify-center gap-2 cursor-pointer transition-all ${
                                                isTrueSelected 
                                                  ? "border-[#0091FF] bg-blue-50 dark:bg-blue-950/60 text-[#0091FF] font-bold shadow-xs" 
                                                  : `bg-white dark:bg-[#071739] text-slate-700 dark:text-slate-300 hover:border-slate-350 ${hasError ? "border-red-300" : "border-slate-200 dark:border-blue-900/50"}`
                                              }`}
                                            >
                                              <div className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-all ${
                                                isTrueSelected ? "border-[#0091FF] bg-[#0091FF]" : "border-slate-300 bg-white"
                                              }`}>
                                                {isTrueSelected && <div className="w-1 h-1 rounded-full bg-white" />}
                                              </div>
                                              <span className="text-xs font-bold">{trueLabel}</span>
                                            </div>

                                            <div 
                                              onClick={() => handleFieldChange(field.id, false)}
                                              className={`p-2.5 rounded-xl border flex items-center justify-center gap-2 cursor-pointer transition-all ${
                                                isFalseSelected 
                                                  ? "border-[#0091FF] bg-blue-50 dark:bg-blue-950/60 text-[#0091FF] font-bold shadow-xs" 
                                                  : `bg-white dark:bg-[#071739] text-slate-700 dark:text-slate-300 hover:border-slate-350 ${hasError ? "border-red-300" : "border-slate-200 dark:border-blue-900/50"}`
                                              }`}
                                            >
                                              <div className={`w-3.5 h-3.5 rounded-full border flex items-center justify-center transition-all ${
                                                isFalseSelected ? "border-[#0091FF] bg-[#0091FF]" : "border-slate-300 bg-white"
                                              }`}>
                                                {isFalseSelected && <div className="w-1 h-1 rounded-full bg-white" />}
                                              </div>
                                              <span className="text-xs font-bold">{falseLabel}</span>
                                            </div>
                                          </div>
                                        );
                                      })()}

                                      {field.type === "dropdown" && field.options && (
                                        <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                                          {field.options.map((opt: any) => {
                                            const isSelected = val === opt.id;
                                            return (
                                              <button
                                                type="button"
                                                key={opt.id}
                                                onClick={() => handleFieldChange(field.id, opt.id)}
                                                className={`p-2.5 rounded-xl border text-xs font-bold transition-all ${
                                                  isSelected
                                                    ? "border-[#0091FF] bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] shadow-xs"
                                                    : "border-slate-200 dark:border-blue-900/50 text-slate-700 dark:text-slate-300 bg-white dark:bg-[#071739] hover:bg-slate-50"
                                                }`}
                                              >
                                                {opt.label?.ar || opt.label}
                                              </button>
                                            );
                                          })}
                                        </div>
                                      )}
                                    </div>

                                    {/* Error Message */}
                                    {hasError && (
                                      <p className="text-[10px] font-bold text-red-500 flex items-center gap-1 animate-fade-in">
                                        <ShieldAlert className="w-3 h-3" />
                                        <span>{validationErrors[field.id]}</span>
                                      </p>
                                    )}
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      ) : (
                        <div className="py-8 text-center bg-slate-50 dark:bg-[#050D24] rounded-2xl border border-slate-200/80 dark:border-blue-900/40 p-4">
                          <p className="text-xs font-bold text-slate-500">
                            هذه الخدمة جاهزة للتسعير المباشر. اضغط على زر "احسب السعر" أدناه.
                          </p>
                        </div>
                      )}

                      {/* Addons selection */}
                      {selectedSubService?.price_config?.options && selectedSubService.price_config.options.length > 0 && (
                        <div className="space-y-3 pt-4 border-t border-slate-100 dark:border-blue-900/40">
                          <label className="block text-xs font-black text-slate-800 dark:text-white">إضافات اختيارية مقترحة</label>
                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
                            {selectedSubService.price_config.options.map((addon: any) => {
                              const isChecked = selectedAddons.includes(addon.key);
                              return (
                                <div
                                  key={addon.key}
                                  onClick={() => handleToggleAddon(addon.key)}
                                  className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
                                    isChecked 
                                      ? "border-[#0091FF] bg-blue-50 dark:bg-blue-950/50 text-[#0091FF]" 
                                      : "border-slate-200 dark:border-blue-900/40 bg-white dark:bg-[#071739] text-slate-700 dark:text-slate-300 hover:border-slate-300"
                                  }`}
                                >
                                  <div className="flex items-center gap-2">
                                    <div className={`w-4 h-4 rounded-md border flex items-center justify-center ${
                                      isChecked ? "border-[#0091FF] bg-[#0091FF] text-white" : "border-slate-300 bg-white dark:bg-slate-800"
                                    }`}>
                                      {isChecked && <Check className="w-3 h-3 stroke-[3]" />}
                                    </div>
                                    <span className="text-xs font-bold">{addon.key}</span>
                                  </div>
                                  <span className="text-[11px] font-black">+{addon.value} ج.م</span>
                                </div>
                              );
                            })}
                          </div>
                        </div>
                      )}
                    </motion.div>
                  )}
                </motion.div>
              )}

                {/* STEP 2: SCHEDULE APPOINTMENT */}
                {currentStep === 1 && (
                  <motion.div
                    key="step-1"
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    transition={{ duration: 0.3, ease: "easeInOut" }}
                    className="space-y-6"
                  >
                    <div>
                      <h2 className="text-xl font-black text-slate-800 dark:text-white">اختيار موعد ويوم الزيارة</h2>
                      <p className="text-slate-500 dark:text-slate-400 text-xs mt-0.5 font-medium">حدد التاريخ والوقت المناسب لحضور فريق العمل المعتمد لمنزلك.</p>
                    </div>

                    {/* Date picker */}
                    <div className="space-y-3">
                      <div className="flex items-center justify-between">
                        <label className="block text-xs font-black text-slate-800 dark:text-white">اليوم المفضل (خلال 30 يوماً)</label>
                        <div className="flex gap-1">
                          <button type="button" onClick={() => scrollDates('right')} className="p-1 rounded-lg border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-600 dark:text-slate-300 hover:bg-slate-100 transition-colors cursor-pointer">
                            <ChevronRight className="w-4 h-4" />
                          </button>
                          <button type="button" onClick={() => scrollDates('left')} className="p-1 rounded-lg border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-600 dark:text-slate-300 hover:bg-slate-100 transition-colors cursor-pointer">
                            <ChevronLeft className="w-4 h-4" />
                          </button>
                        </div>
                      </div>

                      <div 
                        ref={dateScrollRef}
                        className="flex gap-2 overflow-x-auto pb-2 scroll-smooth no-scrollbar"
                        style={{ scrollbarWidth: 'none' }}
                      >
                        {Array.from({ length: 30 }).map((_, idx) => {
                          const d = new Date();
                          d.setDate(d.getDate() + idx);
                          const dateStr = formatDateLocal(d);
                          const isSelected = scheduledDate === dateStr;
                          const isAvailable = availabilityMap[dateStr] !== false;
                          
                          const dayName = d.toLocaleDateString("ar-EG", { weekday: "short" });
                          const dayNum = d.getDate();
                          const monthName = d.toLocaleDateString("ar-EG", { month: "short" });

                          return (
                            <button
                              type="button"
                              key={dateStr}
                              disabled={!isAvailable || isLoadingAvailability}
                              onClick={() => {
                                setScheduledDate(dateStr);
                                setManualDateText(dateStr);
                              }}
                              className={`flex flex-col items-center justify-center p-3 rounded-2xl border min-w-[76px] transition-all cursor-pointer shrink-0 ${
                                !isAvailable 
                                  ? "opacity-35 bg-slate-100 dark:bg-slate-800 border-slate-200 dark:border-slate-700 text-slate-400 cursor-not-allowed" 
                                  : isSelected 
                                    ? "border-[#0091FF] bg-[#0091FF] text-white shadow-md shadow-blue-500/25 scale-105" 
                                    : "border-slate-200 dark:border-blue-900/50 bg-white dark:bg-[#071739] text-slate-700 dark:text-slate-200 hover:border-[#0091FF]"
                              }`}
                            >
                              <span className="text-[10px] font-bold">{dayName}</span>
                              <span className="text-lg font-black my-0.5">{dayNum}</span>
                              <span className="text-[10px] font-bold opacity-80">{monthName}</span>
                            </button>
                          );
                        })}
                      </div>
                    </div>

                    {/* Time Slot Picker */}
                    <div className="space-y-3 pt-4 border-t border-slate-100 dark:border-blue-900/40">
                      <label className="block text-xs font-black text-slate-800 dark:text-white">الفترة الزمنية المفضلة للبدء</label>
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                        {[
                          "09:00 ص",
                          "12:00 م",
                          "03:00 م",
                          "06:00 م"
                        ].map((slot) => {
                          const isSelected = scheduledTime === slot;
                          return (
                            <button
                              type="button"
                              key={slot}
                              onClick={() => setScheduledTime(slot)}
                              className={`p-3 rounded-xl border text-xs font-black transition-all cursor-pointer ${
                                isSelected 
                                  ? "border-[#0091FF] bg-[#0091FF] text-white shadow-md shadow-blue-500/25" 
                                  : "border-slate-200 dark:border-blue-900/50 bg-white dark:bg-[#071739] text-slate-700 dark:text-slate-200 hover:border-[#0091FF]"
                              }`}
                            >
                              {slot}
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  </motion.div>
                )}

                {/* STEP 3: ADDRESS SYSTEM V2 */}
                {currentStep === 2 && (
                  <motion.div
                    key="step-2"
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    transition={{ duration: 0.3, ease: "easeInOut" }}
                    className="space-y-6"
                  >
                    <div>
                      <span className="text-[10px] font-black uppercase px-2.5 py-0.5 rounded-full bg-blue-50 dark:bg-blue-950/70 text-[#0091FF] dark:text-[#22A5FC] border border-blue-100 dark:border-blue-900/60 inline-block mb-1.5">
                        العنوان الجغرافي المعتمد
                      </span>
                      <h2 className="text-xl font-black text-slate-900 dark:text-white">عنوان تقديم الخدمة</h2>
                      <p className="text-slate-500 dark:text-slate-400 text-xs font-medium mt-0.5">
                        يرجى تحديد المحافظة والحي ورقم المبنى بدقة لضمان وصول الفني المعتمد في الموعد المحدد.
                      </p>
                    </div>

                    {/* If user has saved addresses: Select from saved or enter new */}
                    {savedAddresses.length > 0 && (
                      <div className="space-y-3">
                        <div className="flex items-center justify-between">
                          <label className="text-xs font-black text-slate-800 dark:text-slate-200">عناوينك المحفوظة</label>
                          <button
                            type="button"
                            onClick={() => {
                              if (selectedAddressMode === "saved") {
                                setSelectedAddressMode("new");
                                setSelectedSavedAddressId(null);
                              } else {
                                setSelectedAddressMode("saved");
                                if (savedAddresses[0]) {
                                  handleSelectSavedAddress(savedAddresses[0]);
                                }
                              }
                            }}
                            className="text-[11px] font-extrabold text-[#0091FF] dark:text-[#22A5FC] hover:underline flex items-center gap-1 cursor-pointer"
                          >
                            {selectedAddressMode === "saved" ? (
                              <>
                                <Plus className="w-3.5 h-3.5" />
                                <span>إدخال عنوان آخر</span>
                              </>
                            ) : (
                              <>
                                <Navigation className="w-3.5 h-3.5" />
                                <span>اختيار من عناويني المحفوظة</span>
                              </>
                            )}
                          </button>
                        </div>

                        {selectedAddressMode === "saved" && (
                          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            {savedAddresses.map((addr) => {
                              const isSelected = selectedSavedAddressId === addr.id;
                              const fullText = `${addr.governorate || ""}، ${addr.city || ""} - ${addr.district || ""} - ${addr.street_or_compound || addr.street || ""}، مبنى ${addr.building_identifier || addr.building_number || ""}`;
                              return (
                                <div
                                  key={addr.id}
                                  onClick={() => handleSelectSavedAddress(addr)}
                                  className={`p-4 rounded-2xl border text-right transition-all cursor-pointer flex flex-col justify-between space-y-2 ${
                                    isSelected 
                                      ? "border-[#0091FF] bg-blue-50/70 dark:bg-blue-950/50 shadow-sm" 
                                      : "border-slate-200 dark:border-blue-900/50 bg-white dark:bg-[#071739] hover:border-slate-300"
                                  }`}
                                >
                                  <div className="flex items-center justify-between">
                                    <div className="flex items-center gap-2">
                                      <MapPin className={`w-4 h-4 ${isSelected ? "text-[#0091FF]" : "text-slate-400"}`} />
                                      <span className="text-xs font-black text-slate-900 dark:text-white">
                                        {addr.city} - {addr.district || addr.governorate}
                                      </span>
                                    </div>
                                    {addr.is_primary && (
                                      <span className="text-[9px] font-black bg-emerald-50 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-900/50 px-2 py-0.5 rounded-md">
                                        الافتراضي
                                      </span>
                                    )}
                                  </div>
                                  <p className="text-[11px] text-slate-600 dark:text-slate-300 font-medium leading-relaxed">
                                    {fullText}
                                  </p>
                                </div>
                              );
                            })}
                          </div>
                        )}
                      </div>
                    )}

                    {/* Address V2 Input Form (when in new mode or fallback) */}
                    {(selectedAddressMode === "new" || savedAddresses.length === 0) && (
                      <div className="space-y-4 p-4 sm:p-5 rounded-2xl border border-slate-200/80 dark:border-blue-900/50 bg-slate-50/50 dark:bg-[#050D24]/60">
                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                          {/* 1. Governorate */}
                          <div className="space-y-1">
                            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                              المحافظة
                            </label>
                            <select
                              value={address.governorate}
                              onChange={(e) => handleGovernorateChange(e.target.value)}
                              className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                            >
                              {Object.keys(GEOGRAPHIC_HIERARCHY).map((gov) => (
                                <option key={gov} value={gov}>{gov}</option>
                              ))}
                            </select>
                          </div>

                          {/* 2. City */}
                          <div className="space-y-1">
                            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                              المدينة / المنطقة
                            </label>
                            <select
                              value={address.city}
                              onChange={(e) => handleCityChange(e.target.value)}
                              className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                            >
                              {Object.keys(GEOGRAPHIC_HIERARCHY[address.governorate] || {}).map((c) => (
                                <option key={c} value={c}>{c}</option>
                              ))}
                            </select>
                          </div>

                          {/* 3. District */}
                          <div className="space-y-1">
                            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                              الحي / المجاورة
                            </label>
                            <select
                              value={address.district}
                              onChange={(e) => setAddress({ ...address, district: e.target.value })}
                              className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                            >
                              {(GEOGRAPHIC_HIERARCHY[address.governorate]?.[address.city] || ["أخرى"]).map((d) => (
                                <option key={d} value={d}>{d}</option>
                              ))}
                            </select>
                          </div>
                        </div>

                        {/* Custom District if "أخرى" */}
                        {address.district === "أخرى" && (
                          <div className="space-y-1">
                            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                              اسم الحي / المنطقة المخصصة
                            </label>
                            <input
                              type="text"
                              placeholder="اكتب اسم الحي أو المنطقة هنا..."
                              value={customDistrict}
                              onChange={(e) => setCustomDistrict(e.target.value)}
                              className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                            />
                          </div>
                        )}

                        {/* 4. Street or Compound */}
                        <div className="space-y-1">
                          <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                            اسم الشارع أو الكومباوند
                          </label>
                          <input
                            type="text"
                            placeholder="مثال: شارع التسعين الشمالي / كمبوند ميفيدا"
                            value={address.street_or_compound}
                            onChange={(e) => setAddress({ ...address, street_or_compound: e.target.value })}
                            className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                          />
                        </div>

                        {/* 5. Building, Floor, Apartment */}
                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                          <div className="space-y-1">
                            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                              رقم / اسم المبنى أو الفيلا
                            </label>
                            <input
                              type="text"
                              placeholder="مثال: عمارة 42 أو فيلا 18"
                              value={address.building_identifier}
                              onChange={(e) => setAddress({ ...address, building_identifier: e.target.value })}
                              className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                            />
                          </div>

                          <div className="space-y-1">
                            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                              الدور / الطابق <span className="text-slate-400 font-normal">(اختياري)</span>
                            </label>
                            <input
                              type="text"
                              placeholder="مثال: الثالث"
                              value={address.floor}
                              onChange={(e) => setAddress({ ...address, floor: e.target.value })}
                              className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                            />
                          </div>

                          <div className="space-y-1">
                            <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                              رقم الشقة / الوحدة <span className="text-slate-400 font-normal">(اختياري)</span>
                            </label>
                            <input
                              type="text"
                              placeholder="مثال: شقة 12"
                              value={address.apartment_or_unit}
                              onChange={(e) => setAddress({ ...address, apartment_or_unit: e.target.value })}
                              className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                            />
                          </div>
                        </div>

                        {/* 6. Landmark */}
                        <div className="space-y-1">
                          <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">
                            علامة مميزة بالقرب من العقار <span className="text-slate-400 font-normal">(اختياري)</span>
                          </label>
                          <input
                            type="text"
                            placeholder="مثال: بجوار مستشفى الجوي التخصصي / أمام النادي الأهلي"
                            value={address.landmark}
                            onChange={(e) => setAddress({ ...address, landmark: e.target.value })}
                            className="w-full p-2.5 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                          />
                        </div>
                      </div>
                    )}
                  </motion.div>
                )}

                {/* STEP 4: REVIEW & CONTACT */}
                {currentStep === 3 && (
                  <motion.div
                    key="step-3"
                    initial={{ opacity: 0, x: 20 }}
                    animate={{ opacity: 1, x: 0 }}
                    exit={{ opacity: 0, x: -20 }}
                    transition={{ duration: 0.3, ease: "easeInOut" }}
                    className="space-y-6"
                  >
                    <div>
                      <h2 className="text-xl font-black text-slate-800 dark:text-white">بيانات التواصل والتأكيد</h2>
                      <p className="text-slate-500 dark:text-slate-400 text-xs font-medium mt-0.5">خطوتك الأخيرة لإتمام وتأكيد الحجز الفوري مع فريق فريش هوم.</p>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div className="space-y-1.5">
                        <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">الاسم بالكامل</label>
                        <input
                          type="text"
                          placeholder="مثال: محمد أحمد"
                          value={name}
                          onChange={(e) => setName(e.target.value)}
                          className="w-full p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                        />
                      </div>

                      <div className="space-y-1.5">
                        <label className="block text-xs font-bold text-slate-700 dark:text-slate-300">رقم الهاتف (الواتساب)</label>
                        <input
                          type="tel"
                          placeholder="مثال: 01012345678"
                          value={phone}
                          onChange={(e) => setPhone(e.target.value)}
                          className="w-full p-3 rounded-xl border border-slate-200 dark:border-blue-900/60 bg-white dark:bg-[#071739] text-slate-900 dark:text-white text-xs font-bold focus:border-[#0091FF] focus:outline-none"
                        />
                      </div>
                    </div>

                    {/* Payment options */}
                    <div className="space-y-3 pt-4 border-t border-slate-100 dark:border-blue-900/40">
                      <label className="block text-xs font-black text-slate-800 dark:text-white">طريقة الدفع المقترحة</label>
                      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div 
                          onClick={() => setPaymentMethod("cash")}
                          className={`p-3.5 rounded-xl border flex justify-between items-center cursor-pointer transition-all ${
                            paymentMethod === "cash" 
                              ? "border-[#0091FF] bg-blue-50 dark:bg-blue-950/60 text-[#0091FF]" 
                              : "border-slate-200 dark:border-blue-900/50 bg-white dark:bg-[#071739] text-slate-700 dark:text-slate-300"
                          }`}
                        >
                          <span className="text-xs font-bold">نقداً عند انتهاء الخدمة (كاش)</span>
                          <div className={`w-4 h-4 rounded-full border-4 ${paymentMethod === "cash" ? "border-[#0091FF]" : "border-slate-300"}`}></div>
                        </div>
                        <div 
                          onClick={() => setPaymentMethod("instapay")}
                          className={`p-3.5 rounded-xl border flex justify-between items-center cursor-pointer transition-all ${
                            paymentMethod === "instapay" 
                              ? "border-[#0091FF] bg-blue-50 dark:bg-blue-950/60 text-[#0091FF]" 
                              : "border-slate-200 dark:border-blue-900/50 bg-white dark:bg-[#071739] text-slate-700 dark:text-slate-300"
                          }`}
                        >
                          <span className="text-xs font-bold">تحويل إنستا باي / محفظة إلكترونية</span>
                          <div className={`w-4 h-4 rounded-full border-4 ${paymentMethod === "instapay" ? "border-[#0091FF]" : "border-slate-300"}`}></div>
                        </div>
                      </div>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>

              {/* Navigation Actions */}
              <div className="flex justify-between items-center pt-6 border-t border-slate-100 dark:border-blue-900/40 mt-8">
                {currentStep > 0 ? (
                  <button 
                    onClick={handleBack}
                    className="flex items-center gap-1.5 text-xs font-bold text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white transition-colors cursor-pointer"
                  >
                    <ArrowRight className="w-4 h-4 rotate-180" />
                    <span>الرجوع للخلف</span>
                  </button>
                ) : (
                  <Link href="/" className="text-xs font-bold text-slate-400 hover:text-slate-600 dark:hover:text-slate-200">
                    إلغاء والعودة للرئيسية
                  </Link>
                )}

                {currentStep < STEPS.length - 1 ? (
                  currentStep === 0 ? (
                    !selectedSubService ? (
                      <span className="text-xs font-bold text-slate-400">يرجى اختيار الخدمة للمتابعة</span>
                    ) : !hasCalculated ? (
                      <button 
                        type="button"
                        onClick={handleCalculate}
                        disabled={isCalculating}
                        className="flex items-center gap-1.5 bg-[#0091FF] text-white font-extrabold px-6 py-2.5 rounded-xl text-xs shadow-md shadow-blue-500/25 hover:bg-blue-600 transition-all active:scale-95 cursor-pointer"
                      >
                        <span>{isCalculating ? "جاري الحساب..." : "احسب السعر"}</span>
                        <ArrowLeft className="w-4 h-4 rotate-180" />
                      </button>
                    ) : (
                      <button 
                        type="button"
                        onClick={handleNext}
                        className="flex items-center gap-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold px-6 py-2.5 rounded-xl text-xs shadow-md shadow-emerald-600/25 transition-all active:scale-95 cursor-pointer"
                      >
                        <span>الخطوة التالية (الموعد)</span>
                        <ArrowLeft className="w-4 h-4 rotate-180" />
                      </button>
                    )
                  ) : (
                    <button 
                      type="button"
                      onClick={handleNext}
                      disabled={!isStepValid()}
                      className="flex items-center gap-1.5 bg-[#0091FF] disabled:bg-slate-200 dark:disabled:bg-slate-800 disabled:text-slate-400 text-white font-extrabold px-6 py-2.5 rounded-xl text-xs shadow-md shadow-blue-500/25 transition-all active:scale-95 cursor-pointer"
                    >
                      <span>الخطوة التالية</span>
                      <ArrowLeft className="w-4 h-4 rotate-180" />
                    </button>
                  )
                ) : (
                  <button 
                    onClick={handleCompleteBooking}
                    disabled={!isStepValid() || isSubmittingBooking}
                    className="flex items-center gap-2 bg-[#2ECC71] hover:bg-[#27ae60] disabled:bg-slate-200 dark:disabled:bg-slate-800 text-white disabled:text-slate-400 font-black px-7 py-3 rounded-xl text-sm shadow-md shadow-emerald-500/25 transition-all cursor-pointer"
                  >
                    {isSubmittingBooking ? (
                      <span>جاري إتمام حجزك...</span>
                    ) : (
                      <>
                        <ShieldCheck className="w-5 h-5 stroke-[2]" />
                        <span>تأكيد وإتمام الحجز النهائي</span>
                      </>
                    )}
                  </button>
                )}
              </div>
            </motion.div>

            {/* Price invoice details sidebar */}
            <div className="lg:col-span-4 space-y-6 lg:sticky lg:top-[180px] z-20">
              <div className={`bg-white dark:bg-[#071739] rounded-3xl p-5 border border-slate-200/80 dark:border-blue-900/50 shadow-sm space-y-4 transition-all duration-500 ${
                animatePrice ? 'translate-y-0 opacity-100 scale-100' : 'lg:translate-y-2 lg:opacity-90'
              }`}>
                <h3 className="font-black text-slate-900 dark:text-white text-sm sm:text-base border-b border-slate-100 dark:border-blue-900/40 pb-3">
                  ملخص التكلفة والفاتورة
                </h3>
                
                {currentStep === 0 && !hasCalculated ? (
                  <div className="py-8 px-4 text-center space-y-3">
                    <div className="w-12 h-12 rounded-2xl bg-blue-50 dark:bg-blue-950/70 flex items-center justify-center mx-auto text-[#0091FF]">
                      <Sparkles className="w-6 h-6 animate-pulse" />
                    </div>
                    <p className="text-xs font-bold text-slate-500 dark:text-slate-400 leading-relaxed">
                      {selectedSubService 
                        ? "أدخل مواصفات ومقاسات طلبك واضغط على 'احسب السعر' لعرض التكلفة المعتمدة." 
                        : "يرجى تحديد الخدمة المطلوبة من القائمة لحساب تكلفة الحجز."}
                    </p>
                  </div>
                ) : (
                  <>
                    <div className="space-y-3 text-xs text-slate-600 dark:text-slate-300">
                      <div className="flex justify-between items-start gap-3">
                        <span className="font-bold">الخدمة:</span>
                        <span className="text-left font-black text-[#0091FF] dark:text-[#22A5FC]">
                          {selectedSubService?.title?.ar || selectedSubService?.title || "حساب السعر..."}
                        </span>
                      </div>

                      {/* Render input specs breakdown */}
                      {Object.entries(pricingInputs).map(([k, v]) => {
                        const field = selectedSubService?.price_config?.fields?.find((f: any) => f.id === k);
                        if (!field || v === undefined || v === null || v === "" || v === 0) return null;

                        let displayValue = String(v);
                        if (field.type === "toggle") {
                          const optTrue = field.options && field.options.length > 0
                            ? field.options.find((o: any) => o.id === "true" || o.id === "yes")
                            : null;
                          const optFalse = field.options && field.options.length > 1
                            ? field.options.find((o: any) => o.id === "false" || o.id === "no")
                            : null;
                          
                          const trueLabel = optTrue?.label?.ar || optTrue?.label || "نعم";
                          const falseLabel = optFalse?.label?.ar || optFalse?.label || "لا";
                          displayValue = v === true ? trueLabel : falseLabel;
                        } else if (field.type === "dropdown") {
                          const option = field.options?.find((o: any) => o.id === String(v));
                          displayValue = option?.label?.ar || option?.label?.en || option?.label || String(v);
                        } else {
                          displayValue = `${v} ${field.unit || ""}`;
                        }

                        return (
                          <div key={k} className="flex justify-between">
                            <span className="font-bold">{field.label?.ar || field.label}:</span>
                            <span className="font-black text-slate-800 dark:text-white">
                              {displayValue}
                            </span>
                          </div>
                        );
                      })}
                      
                      {/* Selected Addons */}
                      {selectedAddons.length > 0 && selectedSubService?.price_config?.options && (
                        <div className="space-y-1.5 border-t border-slate-100 dark:border-blue-900/30 pt-3">
                          <span className="font-bold block text-slate-400">الإضافات المحددة:</span>
                          {selectedAddons.map((addId) => {
                            const addon = selectedSubService.price_config.options.find((a: any) => a.key === addId);
                            if (!addon) return null;
                            return (
                              <div key={addId} className="flex justify-between text-[11px] font-semibold text-slate-500 dark:text-slate-400">
                                <span>- {addon.key}</span>
                                <span className="font-bold text-[#0091FF]">+{addon.value} ج.م</span>
                              </div>
                            );
                          })}
                        </div>
                      )}
                      
                      {/* Date & Time if selected */}
                      {(scheduledDate || scheduledTime) && (
                        <div className="space-y-2 border-t border-slate-100 dark:border-blue-900/30 pt-3">
                          <span className="font-bold block text-slate-400">الموعد المحدد:</span>
                          {scheduledDate && (
                            <div className="flex items-center gap-1.5 text-[11px] font-bold text-slate-800 dark:text-slate-200">
                              <Calendar className="w-3.5 h-3.5 text-[#0091FF]" />
                              <span>{scheduledDate}</span>
                            </div>
                          )}
                          {scheduledTime && (
                            <div className="flex items-center gap-1.5 text-[11px] font-bold text-slate-800 dark:text-slate-200">
                              <Clock className="w-3.5 h-3.5 text-[#0091FF]" />
                              <span>بين الساعة {scheduledTime}</span>
                            </div>
                          )}
                        </div>
                      )}

                      {/* Location Address V2 Breakdown */}
                      {currentStep >= 2 && (address.street_or_compound || address.building_identifier) && (
                        <div className="space-y-1 border-t border-slate-100 dark:border-blue-900/30 pt-3">
                          <span className="font-bold block text-slate-400">العنوان:</span>
                          <p className="text-[11px] font-bold text-slate-800 dark:text-slate-200 truncate">
                            {address.governorate}، {address.city} - {address.district === "أخرى" ? customDistrict : address.district}
                          </p>
                          <p className="text-[10px] font-medium text-slate-500 dark:text-slate-400 truncate">
                            {address.street_or_compound}، مبنى {address.building_identifier}
                            {address.floor ? `، طابق ${address.floor}` : ""}
                            {address.apartment_or_unit ? `، شقة ${address.apartment_or_unit}` : ""}
                          </p>
                        </div>
                      )}
                    </div>

                    {/* Total Price Card */}
                    <div className="bg-gradient-to-br from-blue-50 to-indigo-50/60 dark:from-[#050D24] dark:to-[#071739] p-4 rounded-2xl border border-blue-100 dark:border-blue-900/50 space-y-2.5">
                      <div className="flex justify-between items-baseline">
                        <span className="text-xs font-black text-slate-700 dark:text-slate-200">المبلغ الإجمالي</span>
                        <div className="text-left">
                          <span className="text-2xl font-black text-[#0091FF] dark:text-[#22A5FC]">
                            {priceDetails.total}
                          </span>
                          <span className="text-xs font-black text-slate-500 dark:text-slate-400 mr-1">ج.م</span>
                        </div>
                      </div>
                      <p className="text-[10px] text-slate-400 font-bold">شامل المعاينة والمعدات وضمان الخدمة</p>
                    </div>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      </main>

      <Footer />
    </>
  );
}

export default function BookingPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen flex items-center justify-center bg-[#F8FAFC] dark:bg-[#040A1C]">
        <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-[#0091FF]"></div>
      </div>
    }>
      <BookingFlowContent />
    </Suspense>
  );
}
