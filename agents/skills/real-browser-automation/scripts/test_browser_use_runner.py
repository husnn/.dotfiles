"""Stdlib-only behavior checks; no browser or API calls."""
import asyncio
import json
import unittest

from browser_use_runner import BridgeStopped, InputBridge


class BridgeTests(unittest.IsolatedAsyncioTestCase):
    async def test_question_then_handoff_and_correlation(self):
        reader = asyncio.StreamReader()
        events = []
        def send(event):
            events.append(event)
            for reply in [[], {"id": "wrong", "answer": "wrong"},
                          {"id": event["id"], "answer": ""},
                          {"id": event["id"], "answer": "done"}]:
                reader.feed_data((json.dumps(reply) + "\n").encode())
        bridge = InputBridge(reader, send=send)
        self.assertEqual(await bridge.ask("Question"), "done")
        self.assertEqual(await bridge.ask("Handoff", "tab A"), "done")
        self.assertEqual([e["type"] for e in events], ["needs_input", "browser_handoff"])
        self.assertNotEqual(events[0]["id"], events[1]["id"])
        self.assertEqual(events[1]["session_reference"], "tab A")
        self.assertIsNone(bridge.pending)

    async def test_pending_until_reply(self):
        reader = asyncio.StreamReader()
        bridge = InputBridge(reader, send=lambda _: None)
        task = asyncio.create_task(bridge.ask("Question"))
        await asyncio.sleep(0)
        self.assertFalse(task.done())
        reader.feed_data((json.dumps({"id": bridge.pending["id"], "answer": "answer"}) + "\n").encode())
        self.assertEqual(await task, "answer")

    async def test_timeout_preserves_pending_request(self):
        bridge = InputBridge(asyncio.StreamReader(), timeout=0.01, send=lambda _: None)
        with self.assertRaisesRegex(BridgeStopped, "input_timeout"):
            await bridge.ask("Question")
        self.assertEqual(bridge.pending["question"], "Question")

    async def test_eof(self):
        reader = asyncio.StreamReader()
        reader.feed_eof()
        with self.assertRaisesRegex(BridgeStopped, "input_closed"):
            await InputBridge(reader, send=lambda _: None).ask("Question")

    async def test_cancel(self):
        reader = asyncio.StreamReader()
        def send(event):
            reader.feed_data((json.dumps({"id": event["id"], "cancel": True}) + "\n").encode())
        with self.assertRaisesRegex(BridgeStopped, "cancelled"):
            await InputBridge(reader, send=send).ask("Question")


if __name__ == "__main__":
    unittest.main()
