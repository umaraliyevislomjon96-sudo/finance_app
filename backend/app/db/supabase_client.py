import logging
# pyrefly: ignore [missing-import]
import httpx
from typing import Dict, Any, List, Optional
from ..core.config import settings

logger = logging.getLogger("aurora.supabase")


class SupabaseClient:
    """
    Supabase Gateway for Spendly / Aurora Finance.
    Handles:
    - PostgREST data queries with RLS enforcement.
    - GoTrue Auth token verification.
    - Realtime WebSockets broadcasting for zero-manual push ingestion.
    
    REGULATORY COMPLIANCE NOTE:
    Under Article 27¹ of the Law of the Republic of Uzbekistan 'On Personal Data',
    personal data of Uzbek citizens must be collected, systematized, and stored
    on physical database servers located within the Republic of Uzbekistan.
    In production, use Self-Hosted Supabase Docker cluster deployed in Tashkent (Servercore/Uztelecom)
    rather than public US/EU Supabase Cloud [Проверить у юриста].
    """

    def __init__(self):
        self.base_url = settings.SUPABASE_URL.rstrip("/") if settings.SUPABASE_URL else ""
        self.anon_key = settings.SUPABASE_ANON_KEY
        self.service_role_key = settings.SUPABASE_SERVICE_ROLE_KEY

    @property
    def is_configured(self) -> bool:
        return bool(self.base_url and (self.anon_key or self.service_role_key))

    def _get_headers(self, jwt_token: Optional[str] = None, use_service_role: bool = False) -> Dict[str, str]:
        headers = {
            "Content-Type": "application/json",
            "apikey": self.service_role_key if use_service_role else self.anon_key
        }
        if jwt_token:
            headers["Authorization"] = f"Bearer {jwt_token}"
        elif use_service_role:
            headers["Authorization"] = f"Bearer {self.service_role_key}"
        elif self.anon_key:
            headers["Authorization"] = f"Bearer {self.anon_key}"
        return headers

    async def health_check(self) -> Dict[str, Any]:
        """Verifies connectivity to the Supabase PostgREST cluster."""
        if not self.is_configured:
            return {
                "status": "unconfigured",
                "message": "SUPABASE_URL or keys not set in environment. Running in embedded mode."
            }

        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.get(
                    f"{self.base_url}/rest/v1/",
                    headers=self._get_headers()
                )
                return {
                    "status": "connected" if resp.status_code == 200 else "degraded",
                    "status_code": resp.status_code,
                    "endpoint": self.base_url
                }
        except Exception as e:
            return {
                "status": "error",
                "detail": str(e)
            }

    async def query_table(
        self,
        table_name: str,
        select: str = "*",
        filters: Optional[Dict[str, str]] = None,
        jwt_token: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """Queries a table with user JWT to preserve Row Level Security (RLS)."""
        if not self.is_configured:
            return []

        url = f"{self.base_url}/rest/v1/{table_name}?select={select}"
        if filters:
            for k, v in filters.items():
                url += f"&{k}={v}"

        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, headers=self._get_headers(jwt_token=jwt_token))
            if resp.status_code != 200:
                logger.error(f"Supabase query error: {resp.text}")
                return []
            return resp.json()

    async def broadcast_realtime_event(
        self,
        channel: str,
        event: str,
        payload: Dict[str, Any]
    ) -> bool:
        """
        Broadcasts an event via Supabase Realtime HTTP endpoint.
        Used to notify the mobile app immediately when a banking push is parsed in background.
        """
        if not self.is_configured:
            return False

        url = f"{self.base_url}/api/v1/broadcast"
        body = {
            "messages": [
                {
                    "topic": channel,
                    "event": event,
                    "payload": payload
                }
            ]
        }
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                resp = await client.post(
                    url,
                    headers=self._get_headers(use_service_role=True),
                    json=body
                )
                return resp.status_code in (200, 201, 202)
        except Exception as e:
            logger.warning(f"Failed to broadcast realtime event to Supabase: {e}")
            return False

    async def insert_record(
        self,
        table_name: str,
        record: Dict[str, Any],
        jwt_token: Optional[str] = None,
        use_service_role: bool = False
    ) -> Optional[Dict[str, Any]]:
        """Inserts a record into Supabase PostgREST table."""
        if not self.is_configured:
            return None

        url = f"{self.base_url}/rest/v1/{table_name}"
        headers = self._get_headers(jwt_token=jwt_token, use_service_role=use_service_role)
        headers["Prefer"] = "return=representation"

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.post(url, headers=headers, json=record)
                if resp.status_code in (200, 201):
                    res_json = resp.json()
                    return res_json[0] if isinstance(res_json, list) and res_json else res_json
                logger.error(f"Supabase insert error ({resp.status_code}): {resp.text}")
                return None
        except Exception as e:
            logger.warning(f"Failed to insert into Supabase: {e}")
            return None

    async def update_record(
        self,
        table_name: str,
        record_id: str,
        updates: Dict[str, Any],
        jwt_token: Optional[str] = None,
        use_service_role: bool = False
    ) -> Optional[Dict[str, Any]]:
        """Updates a record in Supabase PostgREST table by primary id."""
        if not self.is_configured:
            return None

        url = f"{self.base_url}/rest/v1/{table_name}?id=eq.{record_id}"
        headers = self._get_headers(jwt_token=jwt_token, use_service_role=use_service_role)
        headers["Prefer"] = "return=representation"

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.patch(url, headers=headers, json=updates)
                if resp.status_code in (200, 204):
                    res_json = resp.json() if resp.status_code == 200 else {}
                    return res_json[0] if isinstance(res_json, list) and res_json else res_json
                logger.error(f"Supabase update error ({resp.status_code}): {resp.text}")
                return None
        except Exception as e:
            logger.warning(f"Failed to update Supabase record: {e}")
            return None


supabase_client = SupabaseClient()
