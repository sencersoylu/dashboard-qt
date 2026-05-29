import pytest
import respx
from httpx import Response

from app.rest_client import RestClient


@pytest.mark.asyncio
async def test_get_chambers_returns_list(qapp):
    client = RestClient()
    with respx.mock(base_url="http://localhost:3001/api") as mock:
        mock.get("/chambers").mock(return_value=Response(200, json=[{"id": 1}]))
        result = await client.get_chambers()
        assert result == [{"id": 1}]


@pytest.mark.asyncio
async def test_get_chamber_by_id(qapp):
    client = RestClient()
    with respx.mock(base_url="http://localhost:3001/api") as mock:
        mock.get("/chambers/42").mock(return_value=Response(200, json={"id": 42}))
        result = await client.get_chamber(42)
        assert result == {"id": 42}


@pytest.mark.asyncio
async def test_get_latest_reading(qapp):
    client = RestClient()
    with respx.mock(base_url="http://localhost:3001/api") as mock:
        mock.get("/chambers/1/readings/latest").mock(
            return_value=Response(200, json={"o2": 21.0})
        )
        assert await client.get_latest_reading(1) == {"o2": 21.0}


@pytest.mark.asyncio
async def test_error_emits_turkish_message(qapp):
    client = RestClient()
    received = []
    client.errorOccurred.connect(lambda msg: received.append(msg))
    with respx.mock(base_url="http://localhost:3001/api") as mock:
        mock.get("/chambers").mock(return_value=Response(500, json={"error": "boom"}))
        result = await client.get_chambers()
        assert result is None
        assert received and "sunucu" in received[0].lower()


@pytest.mark.asyncio
async def test_network_error_emits_turkish_message(qapp):
    client = RestClient()
    received = []
    client.errorOccurred.connect(lambda msg: received.append(msg))
    with respx.mock(base_url="http://localhost:3001/api") as mock:
        mock.get("/chambers").mock(side_effect=ConnectionError("nope"))
        result = await client.get_chambers()
        assert result is None
        assert received and "bağlan" in received[0].lower()
