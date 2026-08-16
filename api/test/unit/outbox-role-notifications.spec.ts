import { OutboxWorker } from '../../src/queue/outbox.worker';

describe('outbox role notification routing', () => {
  function workerWith(query: jest.Mock) {
    const mail = { send: jest.fn().mockResolvedValue(undefined) };
    const worker = new OutboxWorker(
      { query } as never,
      mail as never,
      { publish: jest.fn() } as never,
      { sendToDevice: jest.fn() } as never,
    ) as any;
    worker.persistAndPush = jest.fn().mockResolvedValue(undefined);
    return { worker, mail };
  }

  it('notifies the customer and restaurant admin/employee for a confirmed order', async () => {
    const query = jest
      .fn()
      .mockResolvedValueOnce([
        {
          userId: 'customer-id',
          email: 'customer@example.com',
          orderNumber: 'LF-1001',
          status: 'placed',
        },
      ])
      .mockResolvedValueOnce([
        { userId: 'admin-id' },
        { userId: 'employee-id' },
      ]);
    const { worker, mail } = workerWith(query);

    await worker.handleOrder({
      id: 'event-id',
      eventType: 'order.confirmed',
      payload: { orderId: 'order-id' },
    });

    expect(mail.send).toHaveBeenCalledTimes(1);
    expect(worker.persistAndPush).toHaveBeenCalledWith(
      'customer-id',
      'event-id',
      'order_confirmed',
      expect.any(String),
      expect.any(String),
      { orderId: 'order-id', status: 'placed' },
      false,
    );
    expect(worker.persistAndPush).toHaveBeenCalledWith(
      'admin-id',
      'event-id',
      'new_order_admin',
      expect.any(String),
      expect.any(String),
      { orderId: 'order-id', status: 'placed' },
    );
    expect(worker.persistAndPush).toHaveBeenCalledWith(
      'employee-id',
      'event-id',
      'new_order_admin',
      expect.any(String),
      expect.any(String),
      { orderId: 'order-id', status: 'placed' },
    );
  });

  it('notifies the assigned delivery employee', async () => {
    const { worker } = workerWith(
      jest
        .fn()
        .mockResolvedValue([
          { driverUserId: 'driver-id', orderId: 'order-id' },
        ]),
    );

    await worker.handleDeliveryAssignment({
      id: 'event-id',
      payload: { assignmentId: 'assignment-id' },
    });

    expect(worker.persistAndPush).toHaveBeenCalledWith(
      'driver-id',
      'event-id',
      'delivery_assigned',
      expect.any(String),
      expect.any(String),
      { orderId: 'order-id', assignmentId: 'assignment-id' },
    );
  });
});
