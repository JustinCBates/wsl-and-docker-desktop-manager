"""Run adapter.run_flow in a background thread and stream progress events to a Queue.

Usage:
    from src.ui.threaded_runner import run_flow_in_thread
    q = queue.Queue()
    run_flow_in_thread('uninstall', {'dry_run': True}, q)
    # drain q until you see a 'run-end' event
"""
from typing import Any, Dict, Optional
import threading
import queue
import importlib


def _make_queue_put(q: queue.Queue):
    def put(event, event_type):
        try:
            q.put_nowait((event_type, event))
        except Exception:
            # swallow queue errors to avoid aborting orchestration
            pass

    return put


def _normalize_results(results):
    out = []
    for r in results:
        if hasattr(r, 'to_dict'):
            try:
                out.append(r.to_dict())
                continue
            except Exception:
                pass
        # fallback to __dict__ or repr
        if hasattr(r, '__dict__'):
            out.append(dict(r.__dict__))
        else:
            out.append({'repr': repr(r)})
    return out


def run_flow_in_thread(flow_name: str, options: Optional[Dict] = None, event_queue: Optional[queue.Queue] = None) -> threading.Thread:
    """Start adapter.run_flow in a daemon thread and stream events to event_queue.

    The thread will put ('run-start', {...}) at start and ('run-end', {'results': [...]}) when finished.
    Returns the Thread object (daemon=True).
    """
    if options is None:
        options = {}
    if event_queue is None:
        event_queue = queue.Queue()

    def target():
        # lazy import to avoid import cycles
        adapter = importlib.import_module('src.ui.adapter')
        qput = _make_queue_put(event_queue)
        # emit run-start
        qput({'flow': flow_name, 'options': dict(options)}, 'run-start')
        try:
            results = adapter.run_flow(flow_name, dry_run=options.get('dry_run', True), yes=options.get('yes', False), log_path=options.get('log_path', None), targets=options.get('targets', None), progress_cb=qput)
            norm = _normalize_results(results)
            qput({'flow': flow_name, 'results': norm}, 'run-end')
        except Exception as e:
            qput({'flow': flow_name, 'error': repr(e)}, 'error')

    th = threading.Thread(target=target, daemon=True)
    th.start()
    return th
