import { NextRequest, NextResponse } from "next/server";
import { BetaAnalyticsDataClient } from "@google-analytics/data";

export const dynamic = "force-dynamic";

export async function GET(request: NextRequest) {
  try {
    const propertyId = process.env.GA_PROPERTY_ID;
    const clientEmail = process.env.GA_CLIENT_EMAIL;
    const rawPrivateKey = process.env.GA_PRIVATE_KEY;

    if (!propertyId || !clientEmail || !rawPrivateKey) {
      return NextResponse.json(
        {
          success: false,
          error: "Missing Google Analytics credentials in environment variables.",
        },
        { status: 500 }
      );
    }

    const privateKey = rawPrivateKey.replace(/\\n/g, "\n");

    const analyticsDataClient = new BetaAnalyticsDataClient({
      credentials: {
        client_email: clientEmail,
        private_key: privateKey,
      },
    });

    const [response] = await analyticsDataClient.runReport({
      property: `properties/${propertyId}`,
      dateRanges: [
        {
          startDate: "today",
          endDate: "today",
        },
      ],
      dimensions: [
        {
          name: "pagePath",
        },
      ],
      metrics: [
        {
          name: "activeUsers",
        },
        {
          name: "screenPageViews",
        },
      ],
    });

    let totalUsers = 0;
    let totalViews = 0;

    const pages = (response.rows || []).map((row) => {
      const path = row.dimensionValues?.[0]?.value || "";
      const users = parseInt(row.metricValues?.[0]?.value || "0", 10);
      const views = parseInt(row.metricValues?.[1]?.value || "0", 10);

      totalUsers += users;
      totalViews += views;

      return {
        path,
        users,
        views,
      };
    });

    // If GA provides aggregated totals in response.totals, use them for accurate unique activeUsers
    if (response.totals && response.totals.length > 0) {
      const aggregatedUsers = parseInt(response.totals[0].metricValues?.[0]?.value || "", 10);
      const aggregatedViews = parseInt(response.totals[0].metricValues?.[1]?.value || "", 10);
      if (!isNaN(aggregatedUsers)) totalUsers = aggregatedUsers;
      if (!isNaN(aggregatedViews)) totalViews = aggregatedViews;
    }

    return NextResponse.json({
      success: true,
      totalUsers,
      totalViews,
      pages,
    });
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
    return NextResponse.json(
      {
        success: false,
        error: errorMessage,
      },
      { status: 500 }
    );
  }
}
