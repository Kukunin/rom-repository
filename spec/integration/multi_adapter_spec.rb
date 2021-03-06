# encoding: utf-8

RSpec.describe 'Repository with multi-adapters configuration' do
  include_context 'database'

  let(:configuration) {
    ROM::Configuration.new(default: [:sql, uri], memory: [:memory])
  }

  let(:users) { rom.relation(:sql_users) }
  let(:tasks) { rom.relation(:memory_tasks) }

  let(:repo) { Test::Repository.new(rom) }

  before do
    module Test
      class Users < ROM::Relation[:sql]
        gateway :default
        schema(:users, infer: true)
        register_as :sql_users
      end

      class Tasks < ROM::Relation[:memory]
        schema(:tasks) do
          attribute :user_id, ROM::Types::Int
          attribute :title, ROM::Types::String
        end

        register_as :memory_tasks
        gateway :memory

        use :key_inference

        view(:base, [:user_id, :title]) do
          self
        end

        def for_users(users)
          restrict(user_id: users.map { |u| u[:id] })
        end
      end

      class Repository < ROM::Repository[:sql_users]
        relations :memory_tasks

        def users_with_tasks(id)
          aggregate(many: { tasks: memory_tasks }).where(id: id)
        end
      end
    end

    configuration.register_relation(Test::Users)
    configuration.register_relation(Test::Tasks)

    user_id = configuration.gateways[:default].dataset(:users).insert(name: 'Jane')
    configuration.gateways[:memory].dataset(:tasks).insert(user_id: user_id, title: 'Jane Task')
  end

  specify 'ᕕ⁞ ᵒ̌ 〜 ᵒ̌ ⁞ᕗ' do
    user = repo.users_with_tasks(users.last[:id]).first

    expect(user.name).to eql('Jane')

    expect(user.tasks[0].user_id).to eql(user.id)
    expect(user.tasks[0].title).to eql('Jane Task')
  end
end
